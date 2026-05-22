#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Anchor/Anchor.xcodeproj"
SCHEME="Anchor"
BUNDLE_ID="com.rbqls6651.anchor"
SIM_ID="${SIM_ID:-4250FC5A-A939-4CD7-BC19-286594CA9FB6}"
OUT_DIR="$ROOT/Marketing/AppStore/Screenshots/raw"
# App Store Connect 허용 세로 크기 (기본 6.7" · 1284×2778). 6.5"는 APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688
APP_STORE_WIDTH="${APP_STORE_WIDTH:-1284}"
APP_STORE_HEIGHT="${APP_STORE_HEIGHT:-2778}"
DERIVED="$ROOT/Anchor/build/DerivedData-Screenshots"
LOG="/tmp/anchor-screenshot-export.log"

SCREENS=(
  today
  routine
  guideRelief
  guideHow
  history
  settingsScreenTime
  settings
)

mkdir -p "$OUT_DIR"

echo ">> Building Keyring for simulator..." | tee "$LOG"
cd "$ROOT/Anchor"

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "$DERIVED" \
  >>"$LOG" 2>&1

APP_PATH=$(find "$DERIVED/Build/Products" -name "Keyring.app" -type d | head -1)
if [[ -z "$APP_PATH" ]]; then
  echo "Keyring.app not found. See $LOG" >&2
  exit 1
fi

echo ">> Booting simulator ${SIM_ID}..." | tee -a "$LOG"
xcrun simctl boot "${SIM_ID}" 2>/dev/null || true
xcrun simctl bootstatus "${SIM_ID}" -b >>"$LOG" 2>&1
open -a Simulator --args -CurrentDeviceUDID "${SIM_ID}" 2>/dev/null || true

xcrun simctl install "${SIM_ID}" "$APP_PATH"

TMP_CAPTURE="/tmp/keyring-screenshots-$$"
mkdir -p "$TMP_CAPTURE"

for name in "${SCREENS[@]}"; do
  echo ">> Capturing ${name}..." | tee -a "$LOG"
  xcrun simctl terminate "${SIM_ID}" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "${SIM_ID}" "$BUNDLE_ID" -ExportAppStoreScreenshots "$name" >>"$LOG" 2>&1
  sleep 3.5
  xcrun simctl io "${SIM_ID}" screenshot "$TMP_CAPTURE/${name}.png"
done

echo ">> Resizing to ${APP_STORE_WIDTH}x${APP_STORE_HEIGHT} and copying to $OUT_DIR"
for name in "${SCREENS[@]}"; do
  sips -z "$APP_STORE_HEIGHT" "$APP_STORE_WIDTH" "$TMP_CAPTURE/${name}.png" --out "$OUT_DIR/${name}.png" >/dev/null
done
rm -rf "$TMP_CAPTURE"

echo ""
echo "Done:"
ls -la "$OUT_DIR"/*.png
