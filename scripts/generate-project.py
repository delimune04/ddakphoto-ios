#!/usr/bin/env python3
"""Generate the committed Xcode project using only the Python standard library.

IDs depend on logical object names, not traversal order. Run this after adding or
removing Swift files; --check verifies that the committed project is current.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
from dataclasses import dataclass


ROOT = Path(__file__).resolve().parent.parent
PROJECT_PATH = ROOT / "DdakPhoto.xcodeproj" / "project.pbxproj"
SCHEME_PATH = ROOT / "DdakPhoto.xcodeproj" / "xcshareddata" / "xcschemes" / "DdakPhoto.xcscheme"


def object_id(name: str) -> str:
    return hashlib.sha1(("ddakphoto:" + name).encode()).hexdigest()[:24].upper()


@dataclass(frozen=True)
class Reference:
    name: str
    comment: str

    def render(self) -> str:
        return f"{object_id(self.name)} /* {self.comment} */"


def render_value(value: object, indent: int) -> str:
    if isinstance(value, Reference):
        return value.render()
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        if not value:
            return "()"
        padding = "\t" * indent
        items = "".join(f"{padding}\t{render_value(item, indent + 1)},\n" for item in value)
        return f"(\n{items}{padding})"
    if isinstance(value, dict):
        if not value:
            return "{}"
        padding = "\t" * indent
        fields = "".join(
            f"{padding}\t{json.dumps(str(key))} = {render_value(item, indent + 1)};\n"
            for key, item in value.items()
        )
        return f"{{\n{fields}{padding}}}"
    raise TypeError(f"Unsupported PBX value: {value!r}")


def make_project() -> tuple[str, str]:
    objects: dict[str, tuple[str, dict]] = {}

    def add(logical_name: str, comment: str, isa: str, **fields: object) -> Reference:
        if logical_name in objects:
            raise ValueError(f"Duplicate object name: {logical_name}")
        objects[logical_name] = (comment, {"isa": isa, **fields})
        return Reference(logical_name, comment)

    app_target = Reference("target:app", "DdakPhoto")
    tests_target = Reference("target:tests", "DdakPhotoTests")
    project = Reference("project", "Project object")
    app_sources: list[Reference] = []
    test_sources: list[Reference] = []
    resources: list[Reference] = []

    def add_file(path: Path, file_type: str, build_phase: list[Reference] | None) -> Reference:
        relative = path.relative_to(ROOT).as_posix()
        ref = add(
            "file:" + relative,
            path.name,
            "PBXFileReference",
            lastKnownFileType=file_type,
            path=path.name,
            sourceTree="<group>",
        )
        if build_phase is not None:
            phase = "Sources" if path.suffix == ".swift" else "Resources"
            build_phase.append(add(
                "build:" + relative,
                f"{path.name} in {phase}",
                "PBXBuildFile",
                fileRef=ref,
            ))
        return ref

    def add_source_group(directory: Path, source_phase: list[Reference]) -> Reference:
        children: list[Reference] = []
        for path in sorted(directory.iterdir(), key=lambda item: item.name):
            if path.is_dir() and path.name != "Resources":
                if any(path.rglob("*.swift")):
                    children.append(add_source_group(path, source_phase))
            elif path.is_file() and path.suffix == ".swift":
                children.append(add_file(path, "sourcecode.swift", source_phase))
        if directory.name == "DdakPhoto":
            resource_directory = directory / "Resources"
            resource_children: list[Reference] = []
            for path in sorted(resource_directory.iterdir(), key=lambda item: item.name):
                if path.suffix == ".xcassets" and path.is_dir():
                    resource_children.append(add_file(path, "folder.assetcatalog", resources))
                elif path.is_file():
                    file_type = "text.plist.xml" if path.suffix in {".plist", ".xcprivacy"} else "file"
                    resource_children.append(add_file(path, file_type, None if path.name == "Info.plist" else resources))
            children.append(add(
                "group:resources", "Resources", "PBXGroup",
                children=resource_children, path="Resources", sourceTree="<group>",
            ))
        return add(
            "group:" + directory.relative_to(ROOT).as_posix(),
            directory.name,
            "PBXGroup",
            children=children,
            path=directory.name,
            sourceTree="<group>",
        )

    app_group = add_source_group(ROOT / "DdakPhoto", app_sources)
    tests_group = add_source_group(ROOT / "DdakPhotoTests", test_sources)
    if not app_sources or not test_sources:
        raise ValueError("Both app and test Swift sources are required.")
    app_product = add(
        "product:app", "DdakPhoto.app", "PBXFileReference",
        explicitFileType="wrapper.application", includeInIndex=0,
        path="DdakPhoto.app", sourceTree="BUILT_PRODUCTS_DIR",
    )
    tests_product = add(
        "product:tests", "DdakPhotoTests.xctest", "PBXFileReference",
        explicitFileType="wrapper.cfbundle", includeInIndex=0,
        path="DdakPhotoTests.xctest", sourceTree="BUILT_PRODUCTS_DIR",
    )
    products_group = add(
        "group:products", "Products", "PBXGroup",
        children=[app_product, tests_product], name="Products", sourceTree="<group>",
    )
    main_group = add(
        "group:main", "Main group", "PBXGroup",
        children=[app_group, tests_group, products_group], sourceTree="<group>",
    )

    def phase(target: str, phase_type: str, files: list[Reference]) -> Reference:
        return add(
            f"phase:{target}:{phase_type}", phase_type, f"PBX{phase_type}BuildPhase",
            buildActionMask=2147483647, files=files, runOnlyForDeploymentPostprocessing=0,
        )

    app_phases = [phase("app", "Sources", app_sources), phase("app", "Frameworks", []), phase("app", "Resources", resources)]
    test_phases = [phase("tests", "Sources", test_sources), phase("tests", "Frameworks", []), phase("tests", "Resources", [])]
    proxy = add(
        "proxy:app", "PBXContainerItemProxy", "PBXContainerItemProxy",
        containerPortal=project, proxyType=1,
        remoteGlobalIDString=app_target, remoteInfo="DdakPhoto",
    )
    dependency = add(
        "dependency:app", "PBXTargetDependency", "PBXTargetDependency",
        target=app_target, targetProxy=proxy,
    )

    project_settings = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "SWIFT_STRICT_CONCURRENCY": "minimal",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated",
        "SWIFT_APPROACHABLE_CONCURRENCY": "NO",
    }
    app_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "DdakPhoto/Resources/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "app.ddakphoto.ios",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SUPPORTS_MACCATALYST": "NO",
        "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
        "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "TARGETED_DEVICE_FAMILY": "1",
    }
    test_settings = {
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@loader_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "app.ddakphoto.ios.tests",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "TARGETED_DEVICE_FAMILY": "1",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DdakPhoto.app/DdakPhoto",
    }

    def configurations(scope: str, base: dict) -> Reference:
        refs: list[Reference] = []
        for name in ["Debug", "Release"]:
            settings = dict(base)
            if scope == "project":
                if name == "Debug":
                    settings.update({
                        "DEBUG_INFORMATION_FORMAT": "dwarf",
                        "ENABLE_TESTABILITY": "YES",
                        "GCC_OPTIMIZATION_LEVEL": "0",
                        "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
                        "ONLY_ACTIVE_ARCH": "YES",
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEBUG",
                        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
                    })
                else:
                    settings.update({
                        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                        "ENABLE_NS_ASSERTIONS": "NO",
                        "ONLY_ACTIVE_ARCH": "NO",
                        "SWIFT_COMPILATION_MODE": "wholemodule",
                        "SWIFT_OPTIMIZATION_LEVEL": "-O",
                        "VALIDATE_PRODUCT": "YES",
                    })
            refs.append(add(
                f"config:{scope}:{name}", name, "XCBuildConfiguration",
                buildSettings=settings, name=name,
            ))
        return add(
            f"configs:{scope}", f'Build configuration list for {scope}', "XCConfigurationList",
            buildConfigurations=refs, defaultConfigurationIsVisible=0, defaultConfigurationName="Release",
        )

    project_configs = configurations("project", project_settings)
    app_configs = configurations("app", app_settings)
    test_configs = configurations("tests", test_settings)
    add(
        app_target.name, app_target.comment, "PBXNativeTarget",
        buildConfigurationList=app_configs, buildPhases=app_phases,
        buildRules=[], dependencies=[], name="DdakPhoto", productName="DdakPhoto",
        productReference=app_product, productType="com.apple.product-type.application",
    )
    add(
        tests_target.name, tests_target.comment, "PBXNativeTarget",
        buildConfigurationList=test_configs, buildPhases=test_phases,
        buildRules=[], dependencies=[dependency], name="DdakPhotoTests", productName="DdakPhotoTests",
        productReference=tests_product, productType="com.apple.product-type.bundle.unit-test",
    )
    add(
        project.name, project.comment, "PBXProject",
        attributes={
            "BuildIndependentTargetsInParallel": "YES",
            "LastSwiftUpdateCheck": "2600",
            "LastUpgradeCheck": "2600",
            "TargetAttributes": {
                object_id(app_target.name): {"CreatedOnToolsVersion": "26.0", "ProvisioningStyle": "Automatic"},
                object_id(tests_target.name): {"CreatedOnToolsVersion": "26.0", "TestTargetID": app_target},
            },
        },
        buildConfigurationList=project_configs,
        compatibilityVersion="Xcode 14.0", developmentRegion="ko",
        hasScannedForEncodings=0, knownRegions=["ko", "en", "Base"],
        mainGroup=main_group, productRefGroup=products_group,
        projectDirPath="", projectRoot="", targets=[app_target, tests_target],
    )

    by_type: dict[str, list[tuple[str, str, dict]]] = {}
    for name, (comment, fields) in objects.items():
        by_type.setdefault(fields["isa"], []).append((name, comment, fields))
    sections: list[str] = []
    for isa, entries in sorted(by_type.items()):
        lines = [f"/* Begin {isa} section */"]
        for name, comment, fields in sorted(entries):
            lines.append(f"\t\t{object_id(name)} /* {comment} */ = {render_value(fields, 2)};")
        lines.append(f"/* End {isa} section */")
        sections.append("\n".join(lines))
    pbx = (
        "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n\n"
        + "\n\n".join(sections)
        + f"\n\t}};\n\trootObject = {project.render()};\n}}\n"
    )
    scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{object_id(app_target.name)}" BuildableName="DdakPhoto.app" BlueprintName="DdakPhoto" ReferencedContainer="container:DdakPhoto.xcodeproj"/>
      </BuildActionEntry>
      <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{object_id(tests_target.name)}" BuildableName="DdakPhotoTests.xctest" BlueprintName="DdakPhotoTests" ReferencedContainer="container:DdakPhoto.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
    <Testables>
      <TestableReference skipped="NO" parallelizable="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{object_id(tests_target.name)}" BuildableName="DdakPhotoTests.xctest" BlueprintName="DdakPhotoTests" ReferencedContainer="container:DdakPhoto.xcodeproj"/>
      </TestableReference>
    </Testables>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{object_id(app_target.name)}" BuildableName="DdakPhoto.app" BlueprintName="DdakPhoto" ReferencedContainer="container:DdakPhoto.xcodeproj"/>
    </BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{object_id(app_target.name)}" BuildableName="DdakPhoto.app" BlueprintName="DdakPhoto" ReferencedContainer="container:DdakPhoto.xcodeproj"/>
    </BuildableProductRunnable>
  </ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
    return pbx, scheme


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if committed project files are stale.")
    args = parser.parse_args()
    pbx, scheme = make_project()
    stale: list[str] = []
    for path, content in [(PROJECT_PATH, pbx), (SCHEME_PATH, scheme)]:
        if args.check:
            if not path.exists() or path.read_text() != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if stale:
        print("Xcode project is stale. Run python3 scripts/generate-project.py:", file=sys.stderr)
        for path in stale:
            print("  " + path, file=sys.stderr)
        return 1
    print("Xcode project is current." if args.check else "Generated DdakPhoto.xcodeproj and shared scheme.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
