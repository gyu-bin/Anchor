# App Store Connect 업로드 (v3 · Figma)

Connect에 올린 **7장 순서**와 동일합니다.

| # | 내용 |
|---|------|
| 1 | 가이드 아침 |
| 2 | 가이드 저녁 |
| 3 | 잠금 |
| 4 | 방법 |
| 5 | 설정 |
| 6 | 오늘 |
| 7 | 결제 |

## Figma (v3 — 이 섹션만 사용)

| 기기 | 섹션 | 프레임 크기 | Connect 슬롯 |
|------|------|-------------|--------------|
| **iPhone** | [iPhone 7장 · Connect · 1284×2778 (v3)](https://www.figma.com/design/2Ob7o24gjnGI22Vkn3KpZv?node-id=57-2) | 1284×2778 | iPhone **6.5"** (및 6.9"에도 동일 파일 업로드 권장) |
| **iPad** | [iPad 7장 · Connect · 2064×2752 (v3)](https://www.figma.com/design/2Ob7o24gjnGI22Vkn3KpZv?node-id=57-51) | 2064×2752 | iPad **13"** |

### Export (중요)

1. `01`~`07` **프레임 전체** 선택 (앱 스크린샷만 X)
2. 우측 Export → **PNG**
3. 배율 **1x 만** (2x/3x 금지)
4.보낸 파일 크기 확인:
   - iPhone: **1284 × 2778**
   - iPad: **2064 × 2752**

```bash
sips -g pixelWidth -g pixelHeight보낸파일.png
```

### Connect 업로드

1. 기존 스크린샷 **전부 삭제** 후 v3 Export 7장을 **순서대로** 드래그
2. iPhone **6.5"** + **6.9"** 둘 다 같은 7장 (6.9" 저장 오류 방지)
3. iPad **13"** 에 iPad v3만 (iPhone 1284 파일 넣지 말 것)

## 인앱 구매 심사 스크린샷

`Full Unlock` → **메타데이터 누락됨** 해소:

- 수익화 → 인앱 구매 → `com.rbqls6651.anchor.unlock`
- **심사용 스크린샷**: `iap-review-paywall.png` (설정 → 「전체 기능 열기」 시트)
- 재생성: `./Scripts/export_iap_paywall_screenshot.sh`
- 표시 이름·설명·가격(₩7,900) 저장

## 개인정보 처리방침 URL

앱 설정: `https://keyring.app/privacy`  
Connect 앱 개인정보 보호에 Notion URL이 있으면, 심사 일관성을 위해 **동일 URL** 권장.
