<div align="center">

# MuscleCheck

**Track your training in 2 seconds. AI handles the rest.**

A radically simple fitness tracker for people who hate logging — built natively for iOS with on-device Apple Intelligence, Siri integration, Apple Watch ecosystem support, and a widget that surfaces your week at a glance.

![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![iOS](https://img.shields.io/badge/iOS-18.1%2B-blue?logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-blue)
![SwiftData](https://img.shields.io/badge/SwiftData-✓-blue)
![Apple Intelligence](https://img.shields.io/badge/Apple%20Intelligence-on--device-purple)
![Tests](https://img.shields.io/badge/tests-Swift%20Testing-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

</div>

---

## Why this exists

Most fitness apps die from logging fatigue. Maxine, Strong, Hevy — they all require recording every set, rep, and weight. Users quit after two weeks.

MuscleCheck takes the opposite bet: a weekly checklist of muscle groups (or yoga sessions, or cardio runs) you tap once when you're done. The app does the rest — streaks, statistics, smart reminders, weekly AI-generated reviews of your training balance, automatic workout detection from HealthKit.

> The app for people who hate logging.

---

## Highlights

| | |
|---|---|
|  **On-device AI coaching** | `FoundationModels` (Apple Intelligence) generates personalized training reviews — zero network, zero cost, full privacy |
|  **Siri integration** | "Hey Siri, log chest in MuscleCheck" — full `AppIntents` implementation with `@ModelActor` for thread-safe SwiftData access from outside the app |
|  **HealthKit auto-detection** | Imports workouts from Apple Watch and other apps, maps `HKWorkoutActivityType` to internal categories, suggests one-tap logging |
|  **Home Screen Widget** | Cross-process data sharing via App Groups + JSON-encoded DTO bridge over `UserDefaults` |
|  **Smart local notifications** | Inactivity reminders ("you haven't trained legs in 5 days") with configurable schedule |
|  **Native charts** | Weekly training trends and muscle frequency analysis with `Swift Charts` |
|  **Progress photos** | Before/after comparison with slider UI, photos stored on disk with SwiftData metadata pointers |
|  **Freemium monetization** | RevenueCat integration with `ProFeatureGate` component, reusable paywall, restore purchases |
|  **Fully localized** | English & Spanish via `Localizable.xcstrings` (Xcode 15 native catalog format) |

---

## Tech Stack

**Language & UI**
Swift 5.0 · SwiftUI · async/await (no Combine)

**Apple Frameworks**
SwiftData · FoundationModels · AppIntents · HealthKit · WidgetKit · WatchKit (planned) · PhotosUI · UserNotifications · Swift Charts

**Third-party**
RevenueCat · Firebase Analytics · Firebase Crashlytics

**Testing**
Swift Testing framework (`@Test`, `#expect`) — not XCTest

**Deployment**
iOS 18.1+ (main app) · iOS 26+ (widget extension)

---

## Architecture

**Pattern:** MVVM + Manager pattern with protocol-based dependency injection.

```
┌──────────────────────────────────────────────────────────────────┐
│                        Presentation                              │
│   SwiftUI Views ⇄ ObservableObject ViewModels ⇄ @Query           │
└──────────────────────────────────────────────────────────────────┘
                              ⇅
┌──────────────────────────────────────────────────────────────────┐
│                          Domain                                  │
│   Managers (each behind a protocol for mockable testing)         │
│   ├─ StoreManager           — RevenueCat purchases & entitlements│
│   ├─ HealthKitManager       — HKHealthStore workout queries      │
│   ├─ NotificationManager    — UNUserNotificationCenter           │
│   ├─ MuscleEntryManager     — SwiftData CRUD (DI'd via context)  │
│   ├─ ProgressPhotoManager   — FileManager + SwiftData pointers   │
│   ├─ MuscleCheckAI          — FoundationModels session wrapper   │
│   ├─ StreakCalculator       — pure functions, no state           │
│   └─ StatsCalculator        — pure functions, no state           │
└──────────────────────────────────────────────────────────────────┘
                              ⇅
┌──────────────────────────────────────────────────────────────────┐
│                        Persistence                               │
│   SwiftData            — MuscleEntry, ProgressPhoto              │
│   FileManager          — image blobs in Documents/ProgressPhotos │
│   UserDefaults         — app preferences                         │
│   App Group Defaults   — widget data bridge (JSON-encoded DTOs)  │
└──────────────────────────────────────────────────────────────────┘
```

### Cross-process data flow (app ↔ widget)

The widget runs as a separate process and cannot access the app's `ModelContainer` directly. Data is bridged through an App Group:

```
┌──────────── Main App Process ─────────────┐    ┌─── Widget Process ───┐
│  SwiftData @Query                         │    │                      │
│       │                                   │    │                      │
│       ▼                                   │    │                      │
│  Map to SharedMuscleEntry (Codable DTO)   │    │                      │
│       │                                   │    │                      │
│       ▼                                   │    │                      │
│  Encode to JSON ──┐                       │    │                      │
│                   ▼                       │    │                      │
│        ┌──────────────────────┐           │    │   ┌────────────────┐ │
│        │ UserDefaults(suite:  │  ◀───────────────▶ │ Decode JSON    │ │
│        │ group.zadkiel.musc…) │           │    │   │ Render timeline│ │
│        └──────────────────────┘           │    │   └────────────────┘ │
└───────────────────────────────────────────┘    └──────────────────────┘
```

### Why `@ModelActor` for App Intents

When Siri triggers an intent, the app may not be running. The main `ModelContainer` doesn't exist in that context. `MuscleDataActor` is a dedicated `@ModelActor` that provides thread-safe SwiftData access from outside the UI process — required for Siri to log a workout without launching the full app.

---

## Project Structure

```
MuscleCheck/                    # Main app target
├── MuscleCheckApp.swift        # @main, Firebase + RevenueCat bootstrap, ModelContainer setup
├── models/                     # SwiftData @Model entities + enums
│   ├── MuscleEntry.swift
│   ├── ProgressPhoto.swift
│   ├── ActivityCategory.swift  # 7 disciplines with presets
│   └── SharedMuscleEntry.swift # Codable DTO for widget bridge
├── managers/
│   ├── protocols/              # Protocols for DI / mocking
│   └── *.swift                 # @MainActor managers
├── viewModels/                 # ObservableObject view models
├── Views/                      # SwiftUI views
│   └── charts/                 # Swift Charts components
├── AppIntents/                 # Siri integration (@ModelActor + AppIntents)
└── extension/                  # Date and Array helpers

MuscleCheckWidget/              # Widget extension target
├── MuscleCheckWidget.swift     # TimelineProvider + EntryView
└── models/
    └── SharedMuscleEntry.swift # Same DTO as main app (shared file ref)

MuscleCheckTests/               # Unit tests (Swift Testing)
├── shared/                     # Mock implementations
│   ├── MockContext.swift       # ModelContextProtocol mock
│   ├── MockStoreManager.swift
│   └── MockNotificationManager.swift
└── *Tests.swift                # One test file per major component
```

---

## Notable implementation details

### Image storage pattern: metadata in SwiftData, blobs on disk

`ProgressPhoto` is a `@Model` with only `id`, `fileName`, `dateTaken`, and `note`. The actual JPEG lives in `Documents/ProgressPhotos/`. This avoids bloating the SQLite store (and the user's iCloud backup quota) with megabytes of binary data, and keeps `@Query` results lightweight enough to render dozens of photo cells without loading all images into memory.

### Protocol-based DI for testability

Every manager that touches an external system (SwiftData, RevenueCat, HealthKit, notifications) has a protocol and a mock counterpart in `MuscleCheckTests/shared/`. Example: `ModelContextProtocol` wraps `ModelContext` so unit tests can run without a real SQLite store.

### `@MainActor` discipline

ViewModels and UI-touching managers are explicitly `@MainActor`. Async work that doesn't need the main thread uses `Task.detached` (e.g., the widget data write happens off the main actor so the UI never blocks).

### Localized AI prompts

`MuscleCheckAI` uses `FoundationModels` with prompts pulled from `Localizable.xcstrings`. The same code generates AI reviews in English or Spanish depending on user locale — no model swap, no separate code paths.

### Calendar configured to start on Monday

A single `Date.appCalendar` extension provides a calendar with `firstWeekday = 2`. All week-of-year logic flows through this, ensuring consistent "weekly checklist" behavior regardless of user locale defaults.

---

## Testing

Tests use Apple's new **Swift Testing** framework (`@Test`, `#expect`) introduced in Xcode 16. Coverage focuses on pure logic and manager behavior:

```
MuscleCheckTests/
├── ContentViewModelTests.swift      — main flow with MockContext
├── HistoryViewModelTests.swift
├── StreakCalculatorTests.swift      — pure function tests
├── StatsCalculatorTests.swift       — pure function tests
├── StoreManagerTests.swift          — with MockStoreManager
├── NotificationManagerTests.swift   — with MockNotificationManager
└── widgetTests/
    └── SharedMuscleEntryTests.swift — DTO Codable round-trip
```

Run with `⌘U` in Xcode or `xcodebuild test -scheme MuscleCheck -destination 'platform=iOS Simulator,name=iPhone 15'`.

---

## Build & Run

**Requirements**
- Xcode 16+
- iOS 18.1+ deployment target
- Apple Intelligence-capable device for AI features (iPhone 15 Pro / 16 / M-series iPad)

**Setup**

```bash
git clone https://github.com/zacdejesus/muscleCheck.git
cd muscleCheck
open MuscleCheck.xcodeproj
```

The project uses Swift Package Manager for dependencies (RevenueCat, Firebase). Xcode resolves them on first open.

**Configuration needed**
- `GoogleService-Info.plist` for Firebase (not committed) — create your own Firebase project
- RevenueCat API key in `StoreManager.swift` is a public test key; replace with your own for production

---

## Roadmap

| Version | Status | Features |
|---|---|---|
| 1.0 – 1.1 | ✅ Shipped | Initial release + Apple Intelligence integration |
| 1.2.0 – 2.0.0 | ✅ Merged | RevenueCat · Settings · Streaks · Stats · Notifications · App Intents · Categories · Progress Photos · HealthKit |
| **2.1.0** | 🚧 In progress | Weight tracking per muscle group · architectural refactors |
| 2.2.0 | ⏳ Planned | Apple Watch app with complications |
| Future | 💭 Exploring | Social/accountability features · weekly AI-generated plans |

---

## Author

**Alejandro De Jesus**
[GitHub](https://github.com/zacdejesus)

Built as a long-running side project to explore the modern Apple stack end-to-end: SwiftData, on-device LLMs, App Intents, HealthKit, and the WidgetKit/App Group story. Feedback and code review welcome.

---

## License

[MIT](LICENSE) © 2026 Alejandro De Jesus

The "MuscleCheck" name and branding are reserved.
