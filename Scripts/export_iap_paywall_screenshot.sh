#!/usr/bin/env bash
# 인앱 구매 심사용 — 설정 → 「전체 기능 열기」 시트
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Anchor/Anchor.xcodeproj"
SCHEME="Anchor"
BUNDLE_ID="com.rbqls6651.anchor"
SIM_ID="${SIM_ID:-850E55FD-5185-46BC-ADC4-6DBB274F16E2}"
OUT_DIR="$ROOT/Marketing/AppStore/Screenshots"
DERIVED="$ROOT/Anchor/build/DerivedData-Screenshots"
LOG="/tmp/anchor-iap-screenshot.log"

mkdir -p "$OUT_DIR" "$OUT_DIR/app-store-2"

echo ">> Building..." | tee "$LOG"
cd "$ROOT/Anchor"
xcodebuild build -project "$PROJECT" -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -derivedDataPath "$DERIVED" >>"$LOG" 2>&1

APP_PATH=$(find "$DERIVED/Build/Products" -name "Keyring.app" -type d | head -1)
[[ -n "$APP_PATH" ]] || { echo "Keyring.app not found. See $LOG"; exit 1; }

xcrun simctl boot "${SIM_ID}" 2>/dev/null || true
xcrun simctl bootstatus "${SIM_ID}" -b >>"$LOG" 2>&1
open -a Simulator --args -CurrentDeviceUDID "${SIM_ID}" 2>/dev/null || true
xcrun simctl install "${SIM_ID}" "$APP_PATH"

TMP="/tmp/keyring-iap-$$.png"
xcrun simctl terminate "${SIM_ID}" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "${SIM_ID}" "$BUNDLE_ID" -ExportAppStoreScreenshots paywallFromSettings >>"$LOG" 2>&1
sleep 4
xcrun simctl io "${SIM_ID}" screenshot "$TMP"

for out in \
  "$OUT_DIR/iap-review-paywall.png" \
  "$OUT_DIR/app-store-2/03-guide-start-paywall.png"; do
  sips -z 2778 1284 "$TMP" --out "$out" >/dev/null
  echo ">> $out"
  sips -g pixelWidth -g pixelHeight "$out"
done

rm -f "$TMP"
echo "Done. Connect → Full Unlock → 심사용 스크린샷에 업로드하세요."
