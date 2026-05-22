#!/usr/bin/env bash
# 가이드 3장 + 방법(참고) — ImageRenderer 대신 시뮬레이터 전체 화면 캡처 (4번과 동일 품질)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Anchor/Anchor.xcodeproj"
SCHEME="Anchor"
BUNDLE_ID="com.rbqls6651.anchor"
SIM_ID="${SIM_ID:-850E55FD-5185-46BC-ADC4-6DBB274F16E2}"
OUT_DIR="$ROOT/Marketing/AppStore/Screenshots/app-store-2"
APP_STORE_WIDTH="${APP_STORE_WIDTH:-1284}"
APP_STORE_HEIGHT="${APP_STORE_HEIGHT:-2778}"
DERIVED="$ROOT/Anchor/build/DerivedData-Screenshots"
LOG="/tmp/anchor-guide-screenshot.log"

SCREENS=(guideMorning guideEvening guideStart guideHow)
SCREEN_FILES=(01-guide-morning.png 02-guide-evening.png 03-guide-start-paywall.png 04-guide-how.png)

mkdir -p "$OUT_DIR"

echo ">> Building..." | tee "$LOG"
cd "$ROOT/Anchor"
xcodebuild build -project "$PROJECT" -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "$DERIVED" >>"$LOG" 2>&1

APP_PATH=$(find "$DERIVED/Build/Products" -name "Keyring.app" -type d | head -1)
[[ -n "$APP_PATH" ]] || { echo "Keyring.app not found"; exit 1; }

xcrun simctl boot "${SIM_ID}" 2>/dev/null || true
xcrun simctl bootstatus "${SIM_ID}" -b >>"$LOG" 2>&1
xcrun simctl install "${SIM_ID}" "$APP_PATH"

TMP="/tmp/keyring-guides-$$"
mkdir -p "$TMP"

for i in "${!SCREENS[@]}"; do
  name="${SCREENS[$i]}"
  out="${SCREEN_FILES[$i]}"
  echo ">> ${name} -> ${out}"
  xcrun simctl terminate "${SIM_ID}" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "${SIM_ID}" "$BUNDLE_ID" -ExportAppStoreScreenshots "$name" >>"$LOG" 2>&1
  sleep 3
  xcrun simctl io "${SIM_ID}" screenshot "$TMP/${name}.png"
  sips -z "$APP_STORE_HEIGHT" "$APP_STORE_WIDTH" "$TMP/${name}.png" \
    --out "$OUT_DIR/${out}" >/dev/null
done
rm -rf "$TMP"

echo "Done:"
ls -la "$OUT_DIR"/*.png
