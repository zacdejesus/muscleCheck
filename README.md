# MuscleCheck

**Track your training in 2 seconds. The AI does the rest.**

MuscleCheck is a weekly training checklist that competes on the opposite end from
spreadsheet-style loggers: **radical simplicity** plus **on-device AI**. Tick a
muscle group (or any discipline — yoga, pilates, running, calisthenics…) when you
train it; the list resets every Monday. Optional depth — per-exercise weights,
reps, duration, distance — lives one tap in, never in the way of the 2-second check.

This is a **monorepo** with two fully native apps that share a product, a design
language, and a set of ported domain semantics — but no code (Swift vs Kotlin):

| | iOS | Android |
|---|---|---|
| UI | SwiftUI | Jetpack Compose (Material 3) |
| Persistence | SwiftData | Room (+ DataStore) |
| Concurrency | async/await | Coroutines + Flow |
| DI | Manager + protocol + `.shared` | Repository + interface + Hilt |
| Widget | WidgetKit | Glance |
| Reminders | UNUserNotificationCenter | WorkManager |
| Images | PhotosUI | Coil + Photo Picker |
| On-device AI | FoundationModels (iOS 26) | *deferred (no equivalent)* |

## Repository layout

```
ios/        Xcode project (app + widget + tests)
android/    Gradle project (Kotlin + Compose)
docs/       Shared plan & design decisions (incl. the Android port plan)
CLAUDE.md   Product context, architecture, roadmap (paths under ios/ are relative to ios/)
```

## Architecture

Both apps follow **MVVM + a testable pure-domain core**. The domain (week
semantics, streak, stats, calendar matrix, inactivity rules) is UI-free and
unit-tested on both platforms — the Android port reuses the iOS test suites as the
spec for the fine-grained semantics (Monday-first weeks with grace, orphan-category
degradation, the 6×7 calendar grid).

Selected decisions worth a look:

- **Per-exercise metrics.** What an entry logs (`none` / weight+reps / duration /
  distance+time) lives on the entry, not the category; the category only supplies
  the default. Additive, migration-verified end-to-end.
- **Exercises inside a group.** A muscle group contains named exercises, each with
  its own history — while the group keeps its own sessions for the weekly check, so
  streak/stats/notifications keep working untouched (minimal blast radius).
- **Additive persistence migrations.** New Codable-nested fields with defaults on
  both platforms, so app updates never wipe existing data.

## Build

**iOS** (Xcode 16+, iOS 18+):
```bash
xcodebuild -project ios/MuscleCheck.xcodeproj -scheme MuscleCheck \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

**Android** (JDK 21, Android SDK 35):
```bash
cd android && ./gradlew testDebugUnitTest assembleDebug
```

## Localization

ES · EN · FR · IT on both platforms.
