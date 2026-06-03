# App Store Review Notes (Keyring 1.0 · build 37+)

Paste the **English** block below into App Store Connect → App Review Information → **Notes**.

---

## English (Review Notes — paste into Connect)

**Device: iPhone only.** This app targets iPhone only (`UIDeviceFamily = iPhone`). iPad screenshots have been removed from App Store Connect. Please review on an **iPhone** for the intended experience (iPad shows a scaled phone UI).

**What Keyring is:** Keyring connects daily routines with iPhone Screen Time. Selected apps and websites stay blocked until the user finishes **today’s routine checklist** on the Today tab — not a fixed timer-only blocker. Quick Lock (Today tab, top-right “즉시잠금”) blocks apps for N minutes without a routine.

**Monetization (no subscription):**
• Free tier from first launch: 3 routines, 5 items per routine, 5 apps, 3 websites, current-month history.
• One-time lifetime unlock: ₩7,900 (Non-Consumable). Product ID: `com.rbqls6651.anchor.unlock`.
• **No 14-day full-feature trial.** IAP is reachable immediately after onboarding.

**Changes in this build (since Guideline 2.1(b) information request):**
1. Removed the 14-day automatic full-feature trial. New users start on the free tier from first launch.
2. **Settings tab → “Full Access” (전체 기능) card → “Unlock Full Access” (전체 기능 열기)** is always visible when not purchased — no device date change needed.
3. Updated App Store description to match: free tier limits + one-time lifetime purchase (no subscription).
4. iPhone-only targeting; iPad store assets removed.

**IAP test path (iPhone):**
1. Complete the in-app guide (8 pages).
2. Open the **Settings** tab (rightmost in the bottom tab bar).
3. At the top, **Full Access** card shows free-tier summary and **Unlock Full Access** (전체 기능 열기).
4. Tap it → paywall sheet → **Unlock forever for ₩7,900** or **Restore Purchases** (구매 복원).

**Sandbox account (IAP review):**
Email: keyring.sandbox.review.2026@gmail.com
Password: ANsrbqls1^^

Sign in on the test device: **iOS Settings → App Store → Sandbox Account** (at the bottom), then follow the IAP test path above.

Paid Apps Agreement is active in App Store Connect (Business section).

**Core feature test path (iPhone):**
1. Complete the guide → allow **Family Controls / Screen Time**.
2. **Routine** tab → create a routine with 2 tasks → pick apps to block (system picker).
3. **Today** tab → check off all tasks → restrictions lift when complete.
4. **Quick Lock** (Today, top-right) → 15-minute block → end early.
5. **History** — calendar; **Settings** — free tier, IAP, restore.

**Privacy policy:** https://keyring.app/privacy

**Contact:** support@keyring.app

---

## 한국어 (참고 · Connect Notes에는 영문만 붙여넣기)

**기기:** iPhone 전용. iPad 스크린샷 제거. iPhone에서 심사해 주세요.

**이번 빌드 변경:**
1. 14일 전체 기능 체험 **폐지** → 처음부터 무료 한도
2. 설정 → 「전체 기능 열기」 **항상 표시** (날짜 변경 불필요)
3. App Store 설명을 무료 한도 + 1회 결제 구조로 갱신

**IAP:** 설정 탭(맨 오른쪽) → 「전체 기능」 → 「전체 기능 열기」 → 구매·복원  
**Sandbox:** keyring.sandbox.review.2026@gmail.com (비밀번호는 Connect Notes 영문 블록 참고)

**차별점:** 체크리스트 완료 전까지 앱·웹 잠금. 즉시잠금 지원. 구독 없음.
