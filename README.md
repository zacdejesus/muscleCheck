# MuscleCheck

[![iOS](https://github.com/zacdejesus/muscleCheck/actions/workflows/ios.yml/badge.svg)](https://github.com/zacdejesus/muscleCheck/actions/workflows/ios.yml)
[![Android](https://github.com/zacdejesus/muscleCheck/actions/workflows/android.yml/badge.svg)](https://github.com/zacdejesus/muscleCheck/actions/workflows/android.yml)
[![App Store](https://img.shields.io/badge/App_Store-live-0EA5E9)](https://apps.apple.com/app/id6748917084)
[![Google Play](https://img.shields.io/badge/Google_Play-live-34A853)](https://play.google.com/store/apps/details?id=com.zadkiel.musclecheck)

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
docs/       Design docs, roadmap and current tasks (see "Design docs" below)
CLAUDE.md   Context for Claude Code: product, architecture, conventions
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

## Design docs

The reasoning behind the code lives in `docs/`. If you have 15 minutes, read in this order:

1. **[Roadmap](docs/roadmap.md)** — where the product stands (pre-PMF), the funnel it's
   measured against, and the bets per stage. The appendix has every feature's design.
2. **[Analytics plan](docs/analytics-plan.md)** — a full design doc for one subsystem:
   the question it answers, the measurement traps specific to a weekly-habit app, the event
   taxonomy, architecture, privacy constraints and risks.
3. **[AI coach tuning](docs/feature12-prompt-tuning.md)** — experiments against Apple's
   on-device model, and why rotation moved out of the prompt and into code.
4. **[Android port plan](docs/android-plan.md)** — the iOS → Android stack mapping and the
   decisions behind a native rewrite over KMP.
5. **[Tech debt](docs/tech-debt.md)** — known debt with its reasoning, including a production
   crash traced back to a double source of truth.

| Doc | Kind |
|---|---|
| `docs/roadmap.md` | Product strategy + feature designs |
| `docs/analytics-plan.md` | Subsystem design doc |
| `docs/feature12-prompt-tuning.md` | Experiment log |
| `docs/feature12-implementation-guide.md` | Implementation guide |
| `docs/android-plan.md` | Port design + phases |
| `docs/tech-debt.md` | Architecture decisions and debt |
| `docs/PENDING.md` | Current task list |

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
