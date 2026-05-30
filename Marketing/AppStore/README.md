# Keyring — App Store 미디어

## 스크린샷 자동 생성 (시뮬레이터)

시뮬레이터에서 앱을 실행해 실제 SwiftUI 화면을 **1284×2778** PNG로 렌더합니다 (App Store 6.7").  
6.5" 슬롯(1242×2688)이면 `APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688 ./Scripts/export_app_store_screenshots.sh`

```bash
chmod +x Scripts/export_app_store_screenshots.sh
./Scripts/export_app_store_screenshots.sh
```

- 시뮬레이터: iPhone 17 Pro Max (다른 기기는 `SIM_ID=... ./Scripts/...`)
- 출력: `Marketing/AppStore/Screenshots/raw/*.png`
- 앱이 `-ExportAppStoreScreenshots` 인자로 잠깐 뜬 뒤 자동 종료됩니다.

수동 촬영이 필요하면 일반 실행 후 시뮬레이터 **⌘S**도 가능합니다.

| 파일 | 화면 |
|------|------|
| `today.png` | 오늘 탭 |
| `routine.png` | 루틴 탭 (아침 루틴 펼침) |
| `guideRelief.png` | 가이드 · 잠금 설명 |
| `guideHow.png` | 가이드 · 사용 방법 |
| `history.png` | 기록 탭 |
| `settingsScreenTime.png` | 설정 · Screen Time 펼침 |
| `settings.png` | 설정 탭 |
| `paywall.png` | 전체 기능 (7,900원) |
| `guideNotification.png` | 가이드 · 알림 |
| `splash.png` | 스플래시 |

Xcode만 사용할 때: **Product → Test** 후 `AppStoreScreenshotExportTests`만 실행해도 됩니다.

## App Store Connect 업로드

1. [App Store Connect](https://appstoreconnect.apple.com) → 앱 → **미디어 관리**
2. **6.9" Display** (또는 6.7") 슬롯에 `raw/*.png` 최대 **10장** (`copy-ko.md` 순서 참고)
3. **앱 미리보기**는 Figma 「미리보기」섹션 참고 · 시뮬레이터 **⌘R** 녹화 15–30초

### iPad (1.0.1+)

앱 타깃은 **iPhone 전용**입니다. Connect에서 **iPad 스크린샷·미리보기 슬롯은 비우거나 제거**하고, 심사 메모에 iPhone-only를 명시하세요 (`REVIEW_NOTES.md` 참고).

## Figma

[App Store · Keyring](https://www.figma.com/design/2Ob7o24gjnGI22Vkn3KpZv) — 스크린샷 10 + 미리보기 3 프레임. `raw/*.png` Export 후 Figma에 교체하거나 스크립트 실행 뒤 Figma 업로드.

**4.3 재제출:** 스크린샷 순서·메타데이터·영문 Reply → `4.3-RESUBMISSION-v2.md` · `copy-ko.md` v2

## 마케팅 문구 (이미지 위 헤드라인용)

`copy-ko.md` 참고. Figma·Canva에서 목업 위에 올리면 됩니다.

## 수동 촬영 (대안)

1. 시뮬레이터 iPhone 16 Pro Max 실행
2. 앱에서 샘플 루틴 채운 뒤 **⌘S** 저장

## 앱 미리보기 (영상)

15–30초, 같은 해상도. 시뮬레이터 **⌘R** 녹화 후 편집.
