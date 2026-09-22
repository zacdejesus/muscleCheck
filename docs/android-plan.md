# MuscleCheck Android — Migration plan

**Decision:** native rewrite in Kotlin + Jetpack Compose (chosen over KMP and Skip).
Separate repo: `~/Desktop/sideProjects/musclecheck-android`. Package `com.zadkiel.musclecheck`
(same as the iOS bundle ID → same RevenueCat and Firebase project).

## Stack mapping

| iOS | Android |
|---|---|
| SwiftUI | Jetpack Compose (Material 3) |
| SwiftData | Room (entities + DAOs with Flow) |
| UserDefaults / App Group | DataStore Preferences |
| WidgetKit | Glance |
| ObservableObject + @Published | ViewModel + StateFlow |
| Manager + protocol + .shared | Repository + interface + Hilt |
| Swift Charts | Hand-rolled Compose charts (2 simple charts, no dependency) |
| UNUserNotificationCenter | WorkManager + POST_NOTIFICATIONS |
| RevenueCat iOS | RevenueCat Android (purchases-android) |
| HealthKit | Health Connect (**deferred to v2**) |
| FoundationModels (AI Coach) | **No equivalent — deferred** (Gemini Nano doesn't cover the whole install base) |
| AppIntents / Siri | Deferred |
| Localizable.xcstrings | strings.xml ES/EN/FR/IT |

## Technical decisions

- **minSdk 26, target/compile 35.** Single module.
- **Week semantics:** `WeekFields(MONDAY, minimalDays=1)` — NOT `WeekFields.ISO`
  (Apple uses `minimumDaysInFirstWeek = 1`; ISO uses 4 and would number some year-boundary weeks
  differently).
- **Icons:** the DB stores the same SF Symbol IDs as iOS (`figure.yoga`, …) for data
  portability; the UI maps them to Material Symbols. Unknown icon → star fallback.
- **Weights always in kg** in storage; kg/lbs conversion at the display edge (same as iOS).
- **Sessions:** their own table with an FK to the entry (idiomatic relational), not embedded JSON
  like SwiftData.
- **Domain tests ported from the Swift suites** — they are the spec for the subtle semantics
  (weekly streak with grace, orphaned-category degradation, Monday-first 6×7 grid).

## Phases

1. ✅ Toolchain (JDK 21 via brew, Android cmdline-tools, platform 35)
2. ✅ Gradle scaffold + pure domain with tests (JVM)
3. ✅ Data layer: Room + DataStore + repositories
4. ✅ Core UI loop: weekly checklist + add group + weight modal
5. ✅ History + stats + streak card
6. ✅ Settings (units, theme, custom categories, presets) + onboarding
7. ✅ Notifications (WorkManager) · Glance widget · progress photos
   - Notifications: `InactivityCalculator` (pure domain, 11 tests ported from the iOS suite),
     `ReminderScheduler` (periodic daily + one-shot inactivity tomorrow at 10:00, re-enqueued
     when going to background via ProcessLifecycleOwner), workers with @HiltWorker, toggle + time
     picker in Settings with the POST_NOTIFICATIONS permission (API 33+). The inactivity summary
     is computed when it fires (not when scheduled, as on iOS) → it's never stale.
   - Widget: Glance 2×2 with the streak (🔥 current / 🏆 max) + the week's checklist (up to 5).
     Reads Room directly via a Hilt EntryPoint (no App Group). `MuscleRepository` refreshes the
     widget after every mutation (mirror of iOS's reloadTimelines). No per-activity icons in v1
     (Glance doesn't render ImageVectors; consider per-category drawables).
   - Progress photos: `ProgressPhotoEntity` (Room, metadata) + the image in internal storage
     (`filesDir/progress_photos/`, not in the DB — like iOS). `ProgressPhotoRepository` (CRUD +
     file I/O), Coil for thumbnails, Android Photo Picker (`PickVisualMedia`, no permissions),
     `LazyVerticalGrid` gallery grouped by month, viewer with delete, and a before/after slider
     (oldest vs newest, draggable divider with `clipRect`). Camera icon on Home.
     DB at v2 with `fallbackToDestructiveMigration` (zero users). **No Pro gate** yet
     (RevenueCat arrives in phase 8).
8. RevenueCat + paywall, FR/IT localization, final build
   - **FR/IT localization ✅** — `values-fr` and `values-it` complete (116 keys each, checked
     against EN). Now ES/EN/FR/IT like iOS.
   - **Pro architecture ✅** — `ProAccessManager` seam (interface) + `LocalProAccessManager`
     (DataStore-backed stub: `purchase()` turns on the local flag; the RevenueCat swap point is
     documented in the file), `PaywallScreen`/`PaywallViewModel` (Free-vs-Pro table, 3
     packages, subscribe/restore), `ProLockedCard`, gate on progress photos, Subscription section
     in Settings, `PAYWALL` route, ES/EN/FR/IT strings (27 keys) and `PaywallViewModelTest`
     (4 tests). Build + tests green.
   - **Pending (blocked on external setup):** swap the stub for the real RevenueCat SDK
     (purchases-android) — with the seam in place it's a one-class change.
     Blockers: Play Console account (USD 25 + closed test), Play Billing products, Android public
     API key, Android app in the RevenueCat project. Without them the SDK can't fetch offerings.

## External blockers (need action from the developer)

- **Play Console:** account (USD 25) + a 14-day closed test with ~12 testers before production.
- **Firebase:** add the Android app to the existing project → `google-services.json` (the code
  stays ready with Analytics/Crashlytics optional until then).
- **RevenueCat:** add the Android app to the project + Android public API key + Play Billing
  products.
