# MuscleCheck — Project Context

> **Monorepo.** iOS (SwiftUI) in `ios/`, Android (Kotlin/Compose) in `android/`, shared docs
> in `docs/`. iOS paths in this file (`models/…`, `Views/…`, `managers/…`) are relative to
> `ios/MuscleCheck/`. CI: build + unit tests per platform on every PR (`.github/workflows/`).

## Where things live

| Doc | What's in it |
|---|---|
| `docs/PENDING.md` | What's left to do right now. Changes on every PR. |
| `docs/roadmap.md` | Release history, feature designs (done and deferred), user-feedback backlog. |
| `docs/analytics-plan.md` | Event names and funnel — single source for iOS and Android. |
| `docs/tech-debt.md` | Known debt and operational risks. |

This file holds only what stays true across releases. Status goes in PENDING, designs in roadmap.

## Current focus

Priorities, in order:

1. **Polish.** This project is a portfolio piece shown in interviews: code, repo, docs and
   the app itself should hold up to a reviewer reading them cold. Prefer finishing and
   tightening what exists over starting something new.
2. **Adoption.** Get real people using it: marketing plus product iteration driven by usage.
   North Star: weekly active users (≥1 `activity_checked` in the week). See
   `docs/analytics-plan.md`.
3. **Code improvements while learning.** Refactors, tests, patterns — also a way for the
   developer to sharpen the SwiftUI/Compose side.

**Rule:** product changes are in scope now (priority 2), but the developer decides them.
Propose, don't build, unless explicitly asked.

## Vision & positioning

**Tagline:** "Track your workout in 2 seconds. AI does the rest."

MuscleCheck is the opposite of training apps that make you log every set, rep and weight. The
differentiator is **radical simplicity** plus **AI that works for the user**. Not gym-only:
yoga, pilates, calisthenics, cardio, stretching, any discipline.

The pillars (details and status in `docs/roadmap.md`):
1. **Zero-effort tracking** — "the training app for people who hate logging".
2. **Personal AI coach** — "a coach who knows you, not a spreadsheet".
3. **Visual progress + Apple ecosystem** — widget, HealthKit, photos, Watch.
4. **Social / accountability** — future.

**The invariant that protects the positioning:** the weekly check stays a 2-second tap. Any
detail (exercises, metrics, values) is optional and never sits on the check's happy path.

## Monetization

Freemium with "AI Pro" via RevenueCat. Suggested prices: $1.99/mo · $14.99/yr · $29.99 lifetime.

> **What's actually gated today:** only **HealthKit (auto-detection)** and **Progress photos**.
> **Stats and notifications ship free**, and the paywall (`PlanComparisonView`) says so. To
> gate anything else, change the feature's view **and** the paywall table **and** this table
> together.

| Free | Pro |
|---|---|
| Weekly checklist | HealthKit auto-detection |
| History (calendar + detail) | Progress photos with timeline |
| Widget | Imbalance detection *(planned)* |
| AI coach: suggested day + exercises (unlimited) | Auto-generated weekly plan *(planned)* |
| Categories + basic presets | Apple Watch app *(deferred)* |
| Statistics (Swift Charts) | |
| Notifications / reminders | |

## Architecture

**Pattern:** MVVM + managers with protocol-based DI (like `ModelContextProtocol` / `MockContext`).

**Stack:** SwiftUI + SwiftData · FoundationModels (Apple Intelligence, on-device) · AppIntents ·
RevenueCat · Firebase (Analytics + Crashlytics) · Swift Charts · WidgetKit + App Groups ·
HealthKit · PhotosUI.

## Code conventions

- PascalCase for types, camelCase for properties/methods
- `@State private var` for SwiftUI state
- `ObservableObject` + `@Published` (don't migrate to `@Observable` yet — keep it consistent)
- Managers as singletons with `.shared`, each with a protocol (for mocks)
- Swift Testing (`@Test`, `#expect`) for unit tests
- `@MainActor` on ViewModels and managers that touch UI
- No Combine — async/await

## Gitflow (solo developer)

`main` is always deployable and tagged for releases. Branches: `feature/`, `fix/`, `refactor/`,
`chore/`. Flow: branch → atomic commits → PR → merge → tag if milestone.
Commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`.

## Instructions for Claude

The developer is senior, historically focused on SDK development, refreshing the UI/SwiftUI
side — not learning iOS from scratch. **Don't write code unless explicitly asked.** The role is
to discuss architecture as a peer, do critical code review, propose trade-offs and answer
specific questions (especially on views/UI). Without a request for code, guide in words.

**Language:** everything written to the repo or GitHub is in **English** — docs, code
comments, commit messages, PR titles, descriptions and comments. The repo is public and part of
a portfolio. Conversation with the developer can be in Spanish; user-facing app copy stays
localized (ES/EN/FR/IT).

## Important notes

- App Group: `group.zadkiel.musclecheck` (widget)
- Bundle ID: `com.zadkiel.musclecheck`
- Calendar starts on Monday (`firstWeekday = 2`)
- Localization ES/EN/FR/IT via a single `Localizable.xcstrings`, member of both the app and
  widget targets
- `PrimaryButtonColor` — color asset used on primary buttons
- SF Symbols for activity icons
