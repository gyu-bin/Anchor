# App Store Review Notes (Keyring 1.0 · build 34+)

Paste the **English** block into App Store Connect → App Review Information → Notes.

---

## English (Review Notes)

**Device: iPhone only.** This build targets iPhone (`UIDeviceFamily = iPhone`). iPad screenshots were removed from App Store Connect. Please review on an iPhone for the intended experience.

**What makes Keyring different:** Selected apps and websites stay blocked until the user finishes **today’s routine checklist** on the Today tab — not a fixed timer-only blocker. Quick Lock (top-right on Today) blocks apps for N minutes without a routine.

**Monetization:** One-time lifetime purchase (₩7,900, no subscription). New users get **14 days of full access**, then free tier limits apply. IAP product ID: `com.rbqls6651.anchor.unlock`.

**Quick test path (iPhone):**
1. Complete or skip the in-app guide (8 pages).
2. Allow **Family Controls / Screen Time** when prompted.
3. **Routine** tab → create a routine (e.g. “Morning”) with 2 tasks → pick apps to block (e.g. Safari) via the system picker.
4. **Today** tab → confirm lock status → check off all tasks → restrictions lift when the routine is complete.
5. **Quick Lock** (Today, top-right “즉시잠금”) → set 15 minutes → confirm block → end early.
6. **History** — completion calendar; **Settings** — 14-day trial status, appearance, guide replay.

**IAP testing:** Sandbox account attached if required. Restore purchases available in Settings.

**Privacy policy:** https://keyring.app/privacy

**Contact:** [your email]

---

## 한국어 (참고)

- **기기:** iPhone 전용. iPad 스크린샷 제거됨. iPhone에서 심사해 주세요.
- **차별점:** 오늘 루틴 할 일을 **전부 완료**하기 전까지만 선택 앱·웹 잠금. 빠른 잠금(즉시잠금) 지원.
- **수익:** ₩7,900 평생 1회, 신규 14일 전체 기능 체험 후 무료 한도.
- **경로:** 가이드 → Screen Time 허용 → 루틴·차단 앱 → 오늘 체크 → 완료 시 해제 → 즉시잠금 확인.
