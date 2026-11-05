# MuscleCheck — Roadmap

> **Stage: pre–product-market fit.** The question is not "what do we build next" but "do
> people arrive, activate, and come back every week?". Every item on this page has to name the
> funnel stage it moves and how we'd know. Right-now tasks live in `docs/PENDING.md`; event
> definitions in `docs/analytics-plan.md`.

## Where we are

- Live on the App Store and Google Play (2.3.0).
- Activation analytics (Phase 1) shipped on iOS in 2.2.2; Android in PR #44.
- Few users: no dashboard will say anything statistically yet. Look for **cliffs**, not
  percentages, and pair every number with a conversation (`analytics-plan.md` §13).

## How we'll know we have PMF

- **North Star:** weekly active users — ≥1 `activity_checked` in the ISO week, by any path
  (app, widget, Siri, HealthKit).
- **The PMF signal for a habit app:** the install-cohort retention curve **flattens** instead of
  decaying to zero — a stable share still checking in weeks 4, 8, 12.
- **Supporting signals:** organic reviews and ratings, installs not explained by our own posts.
- **Later, once there are ~40+ weekly actives:** the "how would you feel if you could no longer
  use MuscleCheck?" survey (≥40% "very disappointed" is the usual bar).

## The funnel

| Stage | The question | How we measure | Status |
|---|---|---|---|
| **1. Acquisition** | Do people who see the store page install? | App Store Connect / Play Console (impressions → page views → installs), `ct=` campaign links | Listing incomplete |
| **2. Activation** | Does a new user reach their first check? | `onboarding_completed` → first `activity_checked` (§7.1) | Instrumented |
| **3. Setup** | Can they add what they actually train? | `exercise_add_started` → `exercise_add_completed`, by `source` (§7.2) | Instrumented |
| **4. Retention** | Do they come back in week 2, and keep coming? | Install cohort → ≥1 check in week 2, 4, 8 (§7.4) | Readable once data exists |
| **5. Advocacy** | Do they tell anyone? | Ratings/reviews, review prompt (2.2.2) | Review prompt shipped |

Monetization is **not** a stage we optimize now (the goal is traction, not revenue).
RevenueCat already covers the paywall funnel; nothing extra gets built for it.

## Bets, by stage

Each bet: the stage it moves, the hypothesis, and what would kill it.

### Now
- **Read the Phase 1 data** (all stages). Nothing else gets prioritized on intuition alone
  once numbers exist.
- **Finish the store listing** (1. Acquisition): subtitle, keywords, ES + EN screenshots
  (iPhone 6.9" + iPad 13"), campaign links per channel. The cheapest lever we haven't pulled.
- **Merge Stats into History** (4. Retention / polish): two screens answer "how much did I
  train?". One screen based on History — summary cards on top, calendar + week detail, "What
  you train most" (muscle frequency) at the bottom; drop the 8-week bar chart (the calendar
  tells the same story). Fewer destinations in the home toolbar. Touches the paywall copy
  ("Statistics" is a free item), the store listing and both platforms.
- **Back up user data to iCloud** (4. Retention / trust): today every check, exercise and
  progress photo lives only in the local SwiftData store, so deleting the app or moving to a
  new iPhone wipes the user's whole history, with no way back short of restoring the entire
  device from an iCloud backup. It happened to the developer on 2026-11-03. Plan: SwiftData
  + CloudKit private database (`ModelConfiguration(cloudKitDatabase: .automatic)`), free for
  everyone: losing data is not something to put behind a paywall. Preconditions: models
  CloudKit can mirror (no `@Attribute(.unique)`, every property optional or with a default,
  optional relationships), a migration for existing local stores, photos as
  `.externalStorage`, and the iCloud + CloudKit capability on the app (the widget keeps
  reading the App Group store). Android needs its own answer (Auto Backup / Drive) — out of
  scope for this bet. Kill signal: none; this is table stakes, not an experiment.

### If the data points there
- **Onboarding ends in a check** (2. Activation) — if the onboarding → first-check drop is
  high, the last onboarding step becomes checking something, not a list to figure out.
- **Rework the add form** (3. Setup) — if adds are started but not completed even though the
  FAB is found (`source=fab` dominates), the problem is the form, not discovery.
- **Question F19's depth** (3. Setup) — if almost nobody opens a group's exercises, that is
  a case for *removing* code, not promoting it.

### Candidates for retention (4)
- **AI coach — suggested day (F12)**: a reason to open the app before training, not only after.
  Kill signal: opened once, never again.
- **Apple Watch (F10)**: zero-effort check from the wrist. Precondition: the share of checks
  arriving outside the app (`source`) — biased low today (Siri is English-only, HealthKit is Pro).
- **Streak reward**: 1 month of Pro at a 12-week streak — a habit reinforcer and a cheap
  conversion channel (RevenueCat supports promotional entitlements). Open: one-time or
  recurring? Reset on a broken streak?

### Parked — pull against the positioning
Detailed per-set logging (F13), live timed sessions (F14), body weight/height profile (F15).
Reasons in appendix D. Revisit only with repeated demand from active users.

## Product principles

The pillars, as a filter for bets rather than a to-do list:
1. **Zero-effort tracking** — the check stays a 2-second tap; everything else is optional.
2. **An AI coach that knows you** — on-device, free, suggests but never checks for you.
3. **Visible progress across the ecosystem** — widget, HealthKit, photos, Watch.
4. **Social / accountability** — later; needs a retained base first.

---

## Appendix

### A. Release history

| Version | What shipped |
|---|---|
| 1.2.0 | RevenueCat integration |
| 1.3.0 | Settings / profile screen |
| 1.4.0 | Streak |
| 1.5.0 | Statistics (Swift Charts) |
| 1.6.0 | Local notifications |
| 1.7.0 | App Intents / Siri |
| 1.8.0 | Customizable activities & categories |
| 1.9.0 | Progress photos |
| 2.0.0 | HealthKit integration |
| 2.1.0 | Weight per muscle group + quality refactors |
| 2.1.2 | Custom categories (F17) + onboarding + Italian localization |
| 2.2.0 | Per-exercise metrics + unified add screen + FAB (F18) + exercises inside a group (F19) — shipped as 2.2.0 (2), Jul 22 |
| 2.2.1 | Home crash fix (`exercisesSummary`) + Crashlytics diagnostics + App Intents without `fatalError` |
| 2.2.2 | Review prompt + activation analytics (Phase 1) |
| 2.3.0 | iOS: AI coach on Private Cloud Compute with on-device fallback, routine scanning (iOS 27), exercise pictograms, iPhone Duo layout. Android (versionCode 3): targetSdk 36, add-sheet data-loss fix, complete color scheme and TalkBack labels, paywall hidden in release until RevenueCat |

### B. Shipped features

**F1 · RevenueCat** — `StoreManager`, `PaywallView`, `ProFeatureGate`.

**F2 · Settings** — subscription, appearance, notifications, about.

**F3 · Streak** — `StreakCalculator`, `StreakViewModel`, `StreakCardView`, streak in the widget.
The streak is **weekly**: consecutive weeks with ≥1 workout; rest days don't break it (matches
the weekly-checklist model). The original calculation was daily-consecutive and clashed with
the app (it sat at 0). The card shows the unit ("weeks in a row"). Grace for the current week:
it drops to 0 only if this week **and** last week are empty.

**F4 · Statistics** — `StatsCalculator`, `StatsViewModel`, `StatsView`, `WeeklyTrainingChart`,
`MuscleFrequencyChart`.

**F5 · Local notifications** — `NotificationManager` behind a protocol, inactivity reminders,
Settings section.

**F6 · App Intents / Siri** — files in `AppIntents/`: `MuscleDataActor` (`@ModelActor` for
SwiftData from intents), `MuscleAppEntity`, `MuscleEntityQuery` (enumerable + string query),
`LogMuscleIntent` (marks a group trained), `GetWeeklyProgressIntent`, `MuscleCheckShortcuts`.
Phrases: "Log MuscleCheck", "I trained [muscle] in MuscleCheck", "What did I train this week
in MuscleCheck". English only.

**F7 · Customizable activities & categories** — `ActivityCategory` enum with 7 disciplines,
presets per category, icon picker, grouped sections on the home screen.

**F8 · Progress photos (Pro)** — `ProgressPhoto` SwiftData model, images on disk (not in the
DB). `ProgressPhotoManager` (CRUD + file I/O), monthly grid gallery, `PhotoCompareView`
before/after slider, `AddProgressPhotoView` with `PhotosPicker`.

**F9 · HealthKit (Pro)** — `HealthKitManager` singleton: authorization, workouts from the last
7 days, `HKWorkoutActivityType` → `ActivityCategory` mapping. `HealthKitSuggestionsView` banner
with Log/Dismiss. Foreground only (no background delivery in v1).

**F11 · Weight per muscle group (2.1.0)** — optional weight per session
(`WorkoutSession.weight`), `ModalWeightView` with auto-focus, kg/lbs toggle (`WeightUnit`),
weight label next to the group name; tapping icon/name/label opens the modal. Swipe-to-log was
dropped: tap already covers it. **Superseded by F18:** "gym only" gating became a per-exercise
`MetricType`.

**F17 · User-defined categories (2.1.2, PR #23)** — users create their own categories (name +
icon + default metric) in Settings and inline from the add screen.
- `CustomCategory` (`@Model`) whose `id` is the same string `MuscleEntry.category` already
  stores → additive migration, old entries untouched.
- `CategoryResolver` (pure): unifies built-in + custom; built-in always wins; a deleted
  category degrades to "Custom" without crashing.
- `CategoryStore`: CRUD over `ModelContextProtocol`, UUID ids, validation, ordered after
  built-ins.
- The AI coach stays gym-only by category string (by design, not by metric).
- **Open:** deleting a category leaves its entries orphaned (shown as "Custom"). Consider
  cascade delete or reassignment.

**F18 · Per-exercise metrics + unified add screen + FAB (2.2.0, PR #27)** — born from user
feedback ("I can't find how to add") and the ask to track time/distance.
- **`MetricType`** per entry: `none` · `strength` (weight + sets + reps) · `duration` ·
  `distanceDuration`. The category only provides the default (gym → strength, running →
  distance + time, cardio/yoga/pilates → time, rest → none).
- Additive migration: `metricRaw == ""` resolves lazily from the category and is persisted by
  an idempotent startup backfill (`backfillMetricTypes`, resolver-aware for custom categories).
- `SessionLogView` shows fields by metric; `WorkoutSession` gained optional `durationSeconds` /
  `distanceMeters` (legacy JSON decodes nil). Storage: kg, meters, seconds (display km-only in
  v1). `SessionFormatting` is the single label formatter (home + history).
- Duplicate-name rule unified and case-insensitive (`MuscleEntryManager.normalizedName`).
- **`AddExerciseView`** replaces `AddMuscleGroupView`: category first (remembers the last one),
  one-tap preset chips (multi-add), free name, metric/icon overrides under Options, inline
  "+ New category" (same `CategoryStore` as Settings).
- **FAB** bottom-right, in the same `safeAreaInset` as the AI coach button (no magic offsets,
  survives Dynamic Type); toolbar "+" removed; empty state with a real CTA.
- **AI coach language:** `it` added, language directive at the end of the prompt,
  `modelSupportsAppLanguage()` + a notice when Siri/Apple Intelligence is in another language
  (the model answers in Siri's language, not the phone's), suggestion cache invalidated on
  language change.

**F19 · Exercises inside a group (2.2.0)** — groups now contain **exercises** (e.g. Legs →
deadlift / hip thrust / calves), each with its own metric and value history. From user
feedback ("better groups per muscle with the exercises inside"). A deliberate cut of F13:
**optional detail, not a mandatory spreadsheet**.
- The group's weekly check doesn't change — tapping the circle = "I trained this", 2 seconds.
- Tapping the group **name** (metric ≠ none) opens `GroupDetailView`: exercise list + "Add
  exercise". Tapping an exercise opens `SessionLogView` (decoupled via `SessionLogTarget`).
- Saving an exercise marks the group trained that day (`MuscleEntry.logExercise`), so streak,
  stats, notifications and HealthKit keep reading the group's sessions untouched (minimal blast
  radius).
- **Model:** `Exercise` is an inline Codable nested in `MuscleEntry.exercises` (same pattern as
  `WorkoutSession`) — no new `@Model`, no `AppSchema` change, no data migration (F11's
  per-group weight is simply not shown in the new UI). Upgrade safety verified end to end in the
  simulator (v1 store → v2 build → data intact, no wipe).
- **Out of scope:** per-set weight, supersets, rest timers.

**F20 · Scan a paper routine (iOS 27, PR #42)** — explicitly requested (Sep 2026). The user
takes a photo of a routine (paper, magazine or screenshot), the on-device model reads it and the
app loads the exercises — **always after an editable review**. The AI proposes a draft; it never
writes to the store without confirmation.

*Gate: iOS 27 only* (FoundationModels image input, `Attachment<ImageAttachmentContent>`). Three
checks: `@available(iOS 27)`, `SystemLanguageModel.availability` and
`capabilities.contains(.vision)` (available ≠ accepts images). Everything builds with Xcode 27
(CI on the `xcode-27` image), so there are no `#if compiler` guards: scanning always compiles
and is tested, and the gate is runtime only.

*Architecture (dependency inversion)*
- `RoutineScanning` (version-agnostic protocol, `@MainActor`) ← `FoundationModelsRoutineScanner`
  (iOS 27). The VM (`RoutineScanViewModel`, iOS 18) gets `(any RoutineScanning)?` injected — no
  `aiStorage: Any?` trick like the coach, and testable with a mock.
- Data shapes: `@Generable ExtractedRoutine` (raw output) → `ScannedRoutine` (what the model
  **read**) → `ScannedExerciseDraft` (what the user **edits**) → real model via `RoutineImport`
  (pure, no LLM or context; new groups come in through an injected closure).
- Persistence lives in `ContentViewModel.importScannedRoutine` (owner of the store and of the
  home refresh).
- Image: `RoutineScanImage.prepare` downsizes to 1600 px and bakes the orientation in one render
  (`CGImage` has no orientation); `@concurrent`, because with Approachable Concurrency a
  `nonisolated async` would run on the main actor.

*Mapping without touching the data model*
- **The group is decided in code, not by index.** The model doesn't see the user's groups (with
  the same muscle in two languages — "Back"/"Espalda", since presets are stored in the language
  of the moment — picking an index failed: "Prensa" → Back, "Bulgares" → Shoulders). It returns
  the muscle as a closed enum (`ExtractedMuscle` → `TargetMuscle`) and `RoutineImport.groupChoice`
  assigns in order: (1) the exercise already exists in a group → that group; (2) muscle →
  `bestGroup` (single-muscle group before a combined one, then most recently trained, then most
  exercises) or a new group with the localized name; (3) no group. **Sheet headings are not
  used**: on device the model filled that field on every row with anything ("legs", "AMRAP",
  the exercise name) and sent a whole PDF to Legs. `TargetMuscle` is an ES/EN/FR/IT synonym
  table over folded text (`NameMatching.fold`: no case, accents or punctuation; "dos" only as a
  whole name).
- **Muscle decided in code first:** `ExerciseCatalog` (~200 common exercises in ES/EN/FR/IT; the
  most specific phrase wins; documented ambiguities: deadlift → back, dips → triceps) → a muscle
  named in the exercise itself → only then the model (`RoutineImport.resolvedMuscle`). Known
  cardio gets no group. Measured on the iPhone output: muscle 79% → 98%, group 83% → 98%.
- Sets/reps on the sheet are a **plan**, not history → stored as a **template session** on the
  exercise with the sentinel date `RoutineImport.templateSessionDate` (`Date.distantPast`). It
  doesn't check the group, doesn't show in history/streak/stats (they read the group's sessions),
  and prefills `SessionLogView` via `lastSets`/`lastReps` until the first real log. **Always
  check with `RoutineImport.isTemplate`, never compare the date by hand.**
- **Language duplicates prevented outside scanning too:** `TargetMuscle.repeatsMuscle(ofName:in:)`
  (same muscle under ANOTHER name in the category; combined groups never count) hides the
  "Pecho" chip on add if "Chest" exists and skips it in `addPresetEntries` (onboarding +
  Settings). `GroupRanking.onePerMuscle` keeps one group per muscle in `WorkoutEligibility` (the
  coach can't suggest "Chest + Pecho", and rest is judged per muscle). Merging existing
  duplicates: deferred (see PENDING).
- **Cleaning the model's output:** "5x5" written whole into reps with empty or 1 sets → use the
  pair (`RoutineImport.splitSetsAndReps`); rows named "none"/"null" (invented on photos that
  aren't routines) are dropped.
- **Vision pre-check before the model** (`RoutineTextGate`): no text → `noText`; text with no
  routine signal (sets×reps pair, catalog exercise or training word) → `notARoutine`. If Vision
  fails, the photo goes through. On the 32 eval images: 28/28 routines pass, 4/4 negatives
  rejected.
- Rep range → **minimum** ("8-12" → 8, "12-10-8" → 8). The draft keeps `reps: Int?` plus
  `repRange` (the sheet's literal); the card shows "Sheet says 8-12 · saving 8" until edited.
  Sets outside 1…20 = misread → nil + amber dot.
- **Sets × reps order:** the prompt gives the convention ("4x8" = 4 sets of 8) and forbids
  swapping. Two-level safety net in code: `setsAndRepsLookSwapped` (sets > 6 and > reps, e.g.
  "8×4") → amber dot; `setsAndRepsLookImplausible` (sets > 10 and reps ≤ 10, e.g. "14×8") →
  "Was it 8 sets of 14?" + a **"Swap"** button. **Never swapped automatically** — a heavy "8×3"
  is real.
- Duplicates (same normalized name in the group) are skipped without touching the existing one.
  A check-only group that receives exercises becomes `.strength` (otherwise `canOpenGroup` would
  hide them).

*UX* (ideas from the design handoff applied on the app's style, not a pixel copy)
- The home **has no FAB anymore**: `HomeActionBar` (`.homeActionBar(...)`; on iOS 26+ a
  transparent `safeAreaBar` with Liquid Glass buttons — `.glass` / `.glassProminent` — and the
  list scrolls under it with the scroll edge effect; on iOS 18–25 a `safeAreaInset` with an
  opaque background; no shadows) stacks the available AI actions ("Suggested day", "Scan
  routine") above a full-width "Add exercise".
- AI actions sit side by side at **equal width** with `EqualWidthHStack` (a `Layout` whose ideal
  width is "widest label × count", so `ViewThatFits` only pairs them when each label fits its
  half — an `HStack` truncated); otherwise (FR/IT, Dynamic Type XXL) they stack.
- **Native buttons:** AI `.glass` (iOS 26+) / `.bordered` `.controlSize(.regular)` subheadline
  semibold; "Add" `.glassProminent` / `.borderedProminent` `.controlSize(.large)`; all
  `.tint(.brand)`. Built from the array of available actions, so both / one / none share one
  layout (the `home.addFAB` id and the `fab` analytics source are kept). Scan copy uses *tú*.
- 4-state sheet: photo → reading (streaming) → **review: one compact card per exercise, always
  expanded** (`surfaceElevated` + `tertiarySystemFill` fields; name, sets and reps with suffix,
  group in a `Menu` on one line; at accessibility sizes the group wraps; doubt = amber `.streak`
  dot; no group = amber border that blocks, with a caption saying what's missing; swipe to
  delete; swipe-to-dismiss disabled) → "Routine loaded · N exercises added".

*Files:* new `models/ScannedRoutine.swift`, `managers/RoutineImport.swift`,
`managers/RoutineScanAI.swift`, `managers/protocols/RoutineScanning.swift`,
`viewModels/RoutineScanViewModel.swift`, `Views/scan/RoutineScanView.swift`,
`Views/scan/ScannedExerciseRow.swift`, tests `RoutineImportTests` / `RoutineScanViewModelTests`.
Modified: `ContentView`, `ContentViewModel`, `Localizable.xcstrings`, camera permission (build
settings). Pending items in `docs/PENDING.md`.

### C. Designed, not built

**F10 · Apple Watch app** — complication showing the streak; tap opens the week's activities;
one tap to check. Sync via WatchConnectivity or shared SwiftData. Stack: WatchKit,
WatchConnectivity, WidgetKit (complications).

**F12 · AI coach — suggested training day.** Replaces the current "review" button
(`reviewLastMonthWorkouts`). Instead of one muscle as text, it suggests a coherent day with
exercises.

*Behavior*
- **Coach, not logger:** suggests, **never checks**. The user checks groups by hand (checking =
  "I trained it"; the semantics stay clean).
- **Free:** the on-device model has no per-call cost.
- Generated from history (no inputs in v1).
- **Push/pull/legs as a soft anchor** → exactly **2 coherent groups** (chest + triceps,
  back + biceps, legs + abs), **3 example exercises** per group (read-only ideas, not a
  mandatory program).
- Prompt logic: rotation across days (inferred from history) → coherence within the day →
  exclude what's already trained today → rest as tiebreaker.
- **"Give me another"** regenerates in one tap.
- **Cached for the day** (UserDefaults): reopenable at the gym, same suggestion until "another"
  or the day changes.
- **Gym only.** iOS 26 gated (FoundationModels); button hidden without Apple Intelligence.

*Output (`@Generable`, iOS 26)*

```swift
@Generable struct WorkoutSuggestion {
  var focus: String          // "Push", "Pull", "Legs"
  var blocks: [Block]        // exactly 2
  var rationale: String
}
@Generable struct Block {
  var groupIndex: Int        // index into the numbered gym groups → robust, no fuzzy matching
  var exercises: [String]    // ~3 examples
}
```

Validate `groupIndex` in range and `blocks.count == 2`; drop or trim what's invalid; map index
→ `MuscleEntry`.

*Architecture*
- `MuscleCheckAI.suggestWorkout(...)` (iOS 26) → `WorkoutSuggestion`, mapped to a flat,
  version-agnostic `RoutineSuggestion` so `ContentViewModel` (iOS 18) can store it — same
  gating pattern already used for FoundationModels.
- Prompt: numbered groups + history (rest per group, trained today) + instructions (soft PPL,
  2 groups, rotation, exclude today, 3 exercises per group, language by locale).
- Modal: focus + rationale + 2 groups with exercises + "Give me another" + close. No "add".
- Use `streamResponse`, not `respond`, to show the suggestion as it generates.

*Model:* Apple's ~3B on-device model. Enough for a narrow task (common exercise knowledge +
simple split + structured output); weak at deep reasoning — mitigated by the narrow task and
"give me another".

*Private Cloud Compute (iOS 27):* on iOS 27 the coach runs on Apple's server model, with each
eligible group's last-4-weeks history to choose between coherent pairs and explain the choice;
the on-device path above is the fallback (offline, over quota, slow or an invalid answer).
Rotation stays in code. Results and the v4 prompt: `docs/feature12-prompt-tuning.md`.

*Prompt tuning (done, on a real device):* see `docs/feature12-prompt-tuning.md`. Key finding:
the model **can't rotate** (doesn't reason over history), so **rotation and variety live in
code** — filter eligible groups and pass only those; exclude the last suggestion for "another".
The model only picks 2 coherent groups + 3 exercises. The doc has the winning instruction.

*Deferred to v2:* time/energy chips, suggesting new groups ("consider adding X"), suggestion
history, curated exercise catalog (the model picks by index → zero hallucination), precomputed
rotation hint.

*Catalog candidate (license pending):* ExerciseDB v1 (mirror
`github.com/hasaneyldrm/exercises-dataset`: 1,324 exercises, JSON + GIF/JPG, EN/ES/IT/TR
instructions, body part / target / secondary-muscle metadata). Blockers: (1) the mirror is
non-commercial → license ExerciseDB at the source (AscendAPI/RapidAPI) since the app is
monetized; (2) the assets would bloat the bundle → ship a small subset per group or fetch on
demand; (3) visual ideas only, gym only — never a path into per-set logging (that's F13).

**Writing to HealthKit — investigated 2026-09-17, not built.**
- **Feasible, and half of it exists:** the `com.apple.developer.healthkit` entitlement is there
  and `INFOPLIST_KEY_NSHealthUpdateUsageDescription` already promises *"MuscleCheck can save your
  training sessions to the Health app"*. Today that promise **isn't kept**: `HealthKitManager`
  asks `requestAuthorization(toShare: [], read: [workoutType])` — read only. Writing means adding
  `HKObjectType.workoutType()` (and any attached quantity types) to `toShare:`.
- **Current API** (verified compiling against the iOS 27 SDK):
  `HKWorkoutBuilder(healthStore:configuration:device:)` → `beginCollection(at:)` →
  `addSamples(_:)` / `addMetadata(_:)` → `endCollection(at:)` → `finishWorkout()`.
  `HKWorkout(activityType:start:end:)` is deprecated since iOS 17. `HKWorkoutConfiguration
  .activityType` takes the types we already map when reading.
- **What our data can express:** `WorkoutSession` stores `date` (real log time), `weight`,
  `sets`, `reps`, `durationSeconds` and `distanceMeters`. *Yes:* `duration` /
  `distanceDuration` entries (yoga, pilates, cardio, running) → a workout with a real start and
  end, plus `distanceWalkingRunning` when there's distance. *No, gym (`strength`):* a workout
  needs start and end and we don't log duration — inventing it puts fake data in Health, asking
  for it breaks the 2-second flow. There's no official sets/reps metadata (`HKMetadata.h`), so
  Health would only show "workout"; without active energy it adds little to the rings, and
  estimating calories would be more invented data.
- **Duplicates, the delicate part:** `HKMetadataKeySyncIdentifier` + `HKMetadataKeySyncVersion`
  replace our previous record when the version is higher (identifier = session UUID, version =
  edit counter) — that fixes duplicating *our* data on re-save. It does **not** fix the echo: a
  session that came from an imported workout (`logHealthKitWorkout`) written back duplicates what
  the Apple Watch already recorded. We don't mark the origin today; it would need an additive
  flag on `WorkoutSession` (e.g. `importedFromHealthKit`) so those are never written.
- **Recommendation:** write only sessions with a real duration, never imported ones, behind Pro
  like reading. If it's not built, change `NSHealthUpdateUsageDescription` so it doesn't promise
  saving.

**Other deferred items**
- Stats: weight evolution per exercise (Swift Charts).
- ExerciseDB catalog when adding an exercise.
- AI coach over the user's real exercises.

**Ideas, not yet designed**
- Location check-in: arrive at the gym, get asked "what did you train today?".
- Daily recommendation push: "Legs today — 5 days since you trained them".
- Imbalance detection: "You train chest 3× more than back" *(planned Pro)*.
- Weekly plan generated from real history *(planned Pro)*.
- HealthKit sync of heart rate and calories.
- Social: share progress with friends, gym groups, weekly challenges.

### D. User-feedback backlog (under evaluation — not approved)

> Recommendations from a tester's review that weren't applied in 2.1.x, kept with their
> trade-offs. Several pull against the core positioning. What *was* applied from that review:
> tap-sensitivity fix ("everything gets deleted"), inline validation on add, and the Free vs Pro
> comparison in the paywall.

**F13 · Detailed logging (sets / reps / weight per set).** *Tension:* this is exactly what
MuscleCheck is *not* — pillar 1 is defined against spreadsheet-style apps. F11 (one optional
weight per session) was the deliberate limit. *If ever built:* an optional advanced mode, off by
default, never on the check's happy path, and only if several users ask — one voice doesn't
justify moving the positioning. **Partly addressed by F19** (exercises with values per session).
What remains out: per-set weight, supersets, rest timers.

**F14 · "Start workout" — live session with a timer.** *Tension:* introduces a timed session
into a weekly-checklist mental model, and overlaps with HealthKit's post-hoc detection (F9). A
paradigm change, not an add-on. *Potential value:* ritual and engagement for people who want a
"gym mode". *Recommendation:* defer; if explored, first validate it doesn't cannibalize the
check's simplicity, and keep it separate from the check flow.

**F15 · Profile with body weight + height.** Cheap to build but **no consumer today** — dead data
without BMI, body-weight tracking over time or AI coach context. Build only together with the
feature that uses it. HealthKit can be the source if it's ever needed.

**F16 · Day-level filter in History.** Today tapping a day shows its **week** (a conscious
choice: more content per tap, working week highlight). Natural follow-up: tap → that day only,
or keep the week but allow collapsing to a day. Low risk; check whether the weekly view already
feels sufficient first.
