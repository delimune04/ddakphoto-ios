#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf '%s\n' 'Usage: ./scripts/archive-ios.sh REAL_TEAM_ID [BUNDLE_ID]' >&2
  printf '%s\n' 'Optional API-key environment: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (all three).' >&2
  exit 2
fi
TEAM_ID="$1"
BUNDLE_ID="${2:-app.ddakphoto.ios}"
if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  printf '%s\n' 'Supply your actual 10-character Apple Developer Team ID.' >&2
  exit 2
fi
if [[ ! "$BUNDLE_ID" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
  printf '%s\n' 'Supply a valid reverse-DNS Bundle ID registered to your team.' >&2
  exit 2
fi
if [[ "$(uname -s)" != Darwin ]]; then
  printf '%s\n' 'Signed iOS archives require macOS with Xcode 26 or newer.' >&2
  exit 1
fi
XCODE_VERSION="$(xcodebuild -version | head -n 1)"
XCODE_MAJOR="${XCODE_VERSION#Xcode }"
XCODE_MAJOR="${XCODE_MAJOR%%.*}"
if [[ ! "$XCODE_MAJOR" =~ ^[0-9]+$ ]] || (( XCODE_MAJOR < 26 )); then
  printf 'Xcode 26 or newer is required; selected toolchain: %s\n' "$XCODE_VERSION" >&2
  exit 1
fi
python3 scripts/generate-project.py --check

# Keep the array nonempty for macOS's system Bash 3.2 with `set -u`.
AUTH_ARGUMENTS=(-allowProvisioningUpdates)
if [[ -n "${ASC_KEY_ID:-}${ASC_ISSUER_ID:-}${ASC_KEY_PATH:-}" ]]; then
  if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" || -z "${ASC_KEY_PATH:-}" ]]; then
    printf '%s\n' 'Set ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_PATH together, or leave all three unset to use your Xcode account.' >&2
    exit 2
  fi
  if [[ ! -r "$ASC_KEY_PATH" ]]; then
    printf '%s\n' 'ASC_KEY_PATH must point to a readable private .p8 key stored outside the repository.' >&2
    exit 2
  fi
  AUTH_ARGUMENTS=(
    -allowProvisioningUpdates
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
fi

BUILD_NUMBER="${DDAKPHOTO_BUILD_NUMBER:-1}"
if [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]{0,3}(\.[0-9]{1,2}){0,2}$ ]]; then
  printf '%s\n' 'DDAKPHOTO_BUILD_NUMBER must be an Apple build version: 1–9999, optionally followed by up to two .0–99 components.' >&2
  exit 2
fi
RELEASE_DIRECTORY="$ROOT_DIR/build/release"
ARCHIVE_PATH="$RELEASE_DIRECTORY/DdakPhoto.xcarchive"
EXPORT_PATH="$RELEASE_DIRECTORY/exports"
mkdir -p "$RELEASE_DIRECTORY" "$EXPORT_PATH"
if [[ -e "$ARCHIVE_PATH" ]]; then
  mv "$ARCHIVE_PATH" "$RELEASE_DIRECTORY/DdakPhoto-previous-$(date +%Y%m%d%H%M%S).xcarchive"
fi

ARCHIVE_ARGUMENTS=(
  -project DdakPhoto.xcodeproj
  -scheme DdakPhoto
  -configuration Release
  -destination 'generic/platform=iOS'
  -archivePath "$ARCHIVE_PATH"
  -derivedDataPath "$ROOT_DIR/build/ReleaseDerivedData"
)
# A fresh CI runner does not need a device-scoped development profile.
# Let exportArchive request distribution signing using the team API key.
# Local Xcode builds keep the usual signed archive path.
if [[ "${DDAKPHOTO_UNSIGNED_ARCHIVE:-0}" == 1 ]]; then
  ARCHIVE_ARGUMENTS+=(CODE_SIGNING_ALLOWED=NO)
else
  ARCHIVE_ARGUMENTS+=("${AUTH_ARGUMENTS[@]}")
fi
ARCHIVE_ARGUMENTS+=(
  "DEVELOPMENT_TEAM=$TEAM_ID"
  "PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID"
  "CURRENT_PROJECT_VERSION=$BUILD_NUMBER"
  CODE_SIGN_STYLE=Automatic
  archive
)
xcodebuild "${ARCHIVE_ARGUMENTS[@]}" | tee "$RELEASE_DIRECTORY/archive.log"

EXPORT_TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/ddakphoto-export.XXXXXX")"
trap 'rm -rf "$EXPORT_TEMP_DIRECTORY"' EXIT
python3 - "$TEAM_ID" "$EXPORT_TEMP_DIRECTORY/ExportOptions.plist" <<'PY'
import plistlib
import sys

options = {
    "method": "app-store-connect",
    "destination": "export",
    "signingStyle": "automatic",
    "teamID": sys.argv[1],
    "manageAppVersionAndBuildNumber": False,
    "stripSwiftSymbols": True,
    "uploadSymbols": True,
}
with open(sys.argv[2], "wb") as handle:
    plistlib.dump(options, handle)
PY
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_TEMP_DIRECTORY/ExportOptions.plist" \
  "${AUTH_ARGUMENTS[@]}" | tee "$RELEASE_DIRECTORY/export.log"

shopt -s nullglob
IPA_FILES=("$EXPORT_PATH"/*.ipa)
if (( ${#IPA_FILES[@]} == 0 )); then
  printf '%s\n' 'Export completed without an IPA. Check the export log.' >&2
  exit 1
fi
printf 'Archive: %s\nExported signed IPA: %s\n' "$ARCHIVE_PATH" "${IPA_FILES[0]}"
printf '%s\n' 'Upload is a separate action; this script does not upload or submit the app for review.'
