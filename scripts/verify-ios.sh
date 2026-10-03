#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != Darwin ]]; then
  printf '%s\n' 'iOS verification requires macOS with Xcode 26 or newer.' >&2
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

DERIVED_DATA="${DDAKPHOTO_DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
ARTIFACTS="$ROOT_DIR/build/verification"
SCREENSHOTS="$ROOT_DIR/release/screenshots"
mkdir -p "$ARTIFACTS" "$SCREENSHOTS"
RESULT_BUNDLE="$ARTIFACTS/DdakPhoto.xcresult"
if [[ -e "$RESULT_BUNDLE" ]]; then
  mv "$RESULT_BUNDLE" "$ARTIFACTS/DdakPhoto-previous-$(date +%Y%m%d%H%M%S).xcresult"
fi
xcodebuild -version > "$ARTIFACTS/environment.txt"
xcrun --sdk iphonesimulator --show-sdk-version >> "$ARTIFACTS/environment.txt"
xcrun simctl list devices available --json > "$ARTIFACTS/available-simulators.json"

# Pick an available large-screen iPhone and the newest installed iOS runtime.
# Do not use the global "booted" alias: another simulator may belong to the user.
python3 - "$ARTIFACTS/available-simulators.json" > "$ARTIFACTS/selected-simulator.txt" <<'PY'
import json
import re
import sys

with open(sys.argv[1]) as handle:
    data = json.load(handle)
candidates = []
for runtime, devices in data.get("devices", {}).items():
    match = re.search(r"iOS-(\d+)-(\d+)(?:-(\d+))?$", runtime)
    if not match:
        continue
    version = tuple(int(value or 0) for value in match.groups())
    if version[0] < 17:
        continue
    for device in devices:
        name = device.get("name", "")
        large_phone = re.fullmatch(r"iPhone (\d+) (Pro Max|Plus)", name)
        if not device.get("isAvailable", False):
            continue
        if not large_phone and name not in {"iPhone XS Max", "iPhone Air"}:
            continue
        generation = int(large_phone.group(1)) if large_phone else (17 if name == "iPhone Air" else 10)
        variant = 2 if name.endswith("Pro Max") else 1
        score = (version, generation, variant, device.get("state") == "Booted")
        candidates.append((score, device))
if not candidates:
    raise SystemExit("No available large-screen iPhone simulator. Install an iOS runtime and an iPhone Pro Max/Plus simulator in Xcode.")
score, device = max(candidates, key=lambda item: item[0])
print("Selected simulator: " + device["name"] + " / iOS " + ".".join(map(str, score[0])), file=sys.stderr)
print(device["udid"], device.get("state", "Shutdown"))
PY
read -r SIMULATOR_UDID SIMULATOR_STATE < "$ARTIFACTS/selected-simulator.txt"

cleanup() {
  xcrun simctl status_bar "$SIMULATOR_UDID" clear >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ "$SIMULATOR_STATE" != Booted ]]; then
  xcrun simctl boot "$SIMULATOR_UDID"
fi
BOOT_READY=0
for attempt in $(seq 1 60); do
  CURRENT_STATE="$(xcrun simctl list devices --json | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devices"]; print(next((device["state"] for group in devices.values() for device in group if device["udid"] == sys.argv[1]), "Missing"))' "$SIMULATOR_UDID")"
  if [[ "$CURRENT_STATE" == Booted ]]; then
    BOOT_READY=1
    break
  fi
  sleep 2
done
if (( BOOT_READY == 0 )); then
  printf 'Simulator failed to boot: %s\n' "$SIMULATOR_UDID" >&2
  exit 1
fi

xcodebuild \
  -project DdakPhoto.xcodeproj \
  -scheme DdakPhoto \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=NO \
  test | tee "$ARTIFACTS/xcodebuild.log"

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/DdakPhoto.app"
if [[ ! -d "$APP_PATH" ]]; then
  printf 'Built simulator app is missing: %s\n' "$APP_PATH" >&2
  exit 1
fi
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl status_bar "$SIMULATOR_UDID" override \
  --time '9:41' --batteryState charged --batteryLevel 100

capture_screen() {
  local name="$1"
  local raw_path="$ARTIFACTS/$name.png"
  xcrun simctl io "$SIMULATOR_UDID" screenshot --type=png "$raw_path"
  python3 - "$raw_path" <<'PY'
from pathlib import Path
import struct
import sys

header = Path(sys.argv[1]).read_bytes()[:24]
if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
    raise SystemExit("Simulator screenshot is not a valid PNG.")
dimensions = struct.unpack(">II", header[16:24])
allowed = {(1260, 2736), (1290, 2796), (1320, 2868), (1242, 2688), (1284, 2778)}
if dimensions not in allowed:
    raise SystemExit(f"Screenshot dimensions {dimensions} do not match supported App Store 6.9/6.5-inch portrait sizes.")
print(f"Verified native screenshot: {dimensions[0]} × {dimensions[1]}")
PY
  # JPEG has no alpha channel, satisfying App Store screenshot requirements.
  sips -s format jpeg -s formatOptions best "$raw_path" \
    --out "$SCREENSHOTS/$name.jpg" >/dev/null
}

xcrun simctl terminate "$SIMULATOR_UDID" app.ddakphoto.ios >/dev/null 2>&1 || true
xcrun simctl launch "$SIMULATOR_UDID" app.ddakphoto.ios \
  --demo -AppleLanguages '(ko)' -AppleLocale ko_KR
sleep 5
capture_screen 01-ready
xcrun simctl terminate "$SIMULATOR_UDID" app.ddakphoto.ios
xcrun simctl launch "$SIMULATOR_UDID" app.ddakphoto.ios \
  --demo --demo-results -AppleLanguages '(ko)' -AppleLocale ko_KR
sleep 8
capture_screen 02-results

printf 'iOS build, XCTest, and native screenshot capture passed.\nResults: %s\nScreenshots: %s\n' \
  "$RESULT_BUNDLE" "$SCREENSHOTS"
