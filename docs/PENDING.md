# Pending — where to start

> Snapshot 2026-09-21. 2.2.2 is live. Priorities and funnel in `docs/roadmap.md`.

## 🚨 Risks first

- **Android Pro is a stub, and the paywall is likely live on Play.** Settings → "Upgrade to Pro"
  opens the paywall with real prices, and "buying" grants Pro locally without charging
  (`LocalProAccessManager`). Present since #29 (Aug 9), so versionCode 2 includes it — confirm
  the live versionCode in Play Console. Beyond free Pro, selling digital goods outside Play
  Billing risks a Payments policy violation. **Short term:** hide the paywall on Android.
  **Real fix:** RevenueCat (one class), blocked on Play Billing products, the Android public API
  key and the Android app in the RevenueCat project.
- **Android keystore (`.jks`) lives only in iCloud Drive.** Keep a copy outside iCloud
  (`docs/tech-debt.md` §0).

## 1 · Polish (portfolio)

- **Open PRs / branches:**
  - #44 Android Firebase — before merging: see events in DebugView, onboarding with clean data
    (`adb shell pm clear com.zadkiel.musclecheck`), a forced crash reaching Crashlytics.
  - `feature/pcc-coach` AI coach on Private Cloud Compute (iOS 27) — before the PR: on the
    iPhone, airplane mode (on-device answers, nothing half-shown), "give me another" 10× in a
    row, see the "no other combination" notice.
  - #42 Scan a paper routine (iOS 27) — not ready: needs a real-device test on iOS 27, English
    PR text, and its CLAUDE.md / PENDING additions moved into `docs/roadmap.md` and here.
- **Restrict the Firebase API keys** in Google Cloud Console: iOS key → bundle ID, Android key →
  package + signing SHA-1. The repo is public.
- Archive/delete the old `~/Desktop/sideProjects/musclecheck-android` repo if it still exists
  (its code lives in `android/`).

## 2 · Adoption

- **Crashlytics:** confirm `MuscleEntry.exercisesSummary.getter` (EXC_BREAKPOINT) doesn't come
  back — the real validation of the 2.2.1 fix.
- **Store listing:** subtitle, keywords, ES + EN screenshots (iPhone 6.9" + iPad 13"),
  campaign links (`ct=`) per channel.
- **Play Data safety** after #44: App activity → App interactions + Crash logs, no ad ID.
- **App Privacy** in App Store Connect (?) — Usage Data → Product Interaction, not linked to
  identity, no tracking. With the PCC coach: confirm nothing changes (data goes to Apple, not
  to us, and isn't stored).
- **GA4 custom dimensions** for `coach_generated`: `engine`, `fallback_reason`,
  `latency_bucket` — unregistered, they don't show up in reports.

## 3 · Code

- **Test bug:** `OnboardingUITests` fails on intra-suite order (the `-resetOnboarding` hook
  doesn't restore first-run after an onboarding already completed in the same clone).
- **Dead code:** `ContentViewModel.saveSession(_:for:)` (iOS) and `HomeViewModel.saveSession` +
  the group-level `SessionLogSheet` (Android, `sessionEntry` is never set). Tested on iOS —
  decide whether to remove on both.
- **Cleanup:** the `.none` case folded into `.strength` inside `SessionLogView`.
- **Copy:** Spanish mixes *tú* and *vos* ("Elegí otra semana", "Todavía no agregaste
  ejercicios") — unify on *tú*, like the rest of the app.
- **CI:** add lint; later, TestFlight distribution.
- **Crashlytics build hang:** `upload-symbols` still hangs local builds (simulator and device
  tests) on `main`. The fix (`e67258e1`: skip the phase on simulator, block only on archive)
  lives on `feature/scan-routine` (#42); bring it to `main` on its own.
