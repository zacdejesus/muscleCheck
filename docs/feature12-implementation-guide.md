# Feature 12 — Implementation guide (AI Coach: suggested day)

Guide to the code changes still needed to close Feature 12. Design in `docs/roadmap.md` →
appendix C, tuning findings in `docs/feature12-prompt-tuning.md`. **This guide explains WHAT to
do and WHY; the snippets are sketches/signatures, not the implementation.**

## Guiding principle (from the experiments)
The on-device model **doesn't reason** over history. So:
- **Rotation is done by CODE** (filtering eligible groups).
- **The model only** picks 2 coherent groups from the ones we pass + 3 exercises each.
- Everything FoundationModels goes behind `@available(iOS 26, *)` (same pattern already used).

## Apple documentation
- Framework: https://developer.apple.com/documentation/FoundationModels
- `LanguageModelSession`: https://developer.apple.com/documentation/foundationmodels/languagemodelsession
- Generating content / tasks: https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models
- Guided generation (`@Generable`/`@Guide`, full example): https://developer.apple.com/documentation/FoundationModels/generate-dynamic-game-content-with-guided-generation-and-tools
- WWDC25 "Meet the Foundation Models framework": https://developer.apple.com/videos/play/wwdc2025/286/
- WWDC25 "Deep dive into the Foundation Models framework" (streaming/PartiallyGenerated): https://developer.apple.com/videos/play/wwdc2025/301/

---

## Step 1 — Eligibility / rotation (in code) ⭐ the key change

**Why:** the model re-suggested what was trained yesterday and fixated on "Legs". Filtering on
our side makes that go away.

**What:** a pure function that, given the `MuscleEntry` array, returns the **gym** groups
eligible today = those NOT trained in the last ~1 day (excludes today and yesterday). Each
`MuscleEntry` has `sessions: [WorkoutSession]`; the last date is `sessions.map(\.date).max()`.

**Where:** new file **`MuscleCheck/managers/WorkoutEligibility.swift`**, following the existing
pure-calculator pattern (`StreakCalculator`, `StatsCalculator`): a `struct` with `static func`.
It's **pure logic** and is **NOT gated to iOS 26** (it doesn't touch FoundationModels).
`ContentViewModel.generateRoutine()` calls it and passes the result to
`MuscleCheckAI.suggestWorkout(eligible:)`.

```swift
// Sketch — you implement it. Goes in MuscleCheck/managers/WorkoutEligibility.swift
struct WorkoutEligibility {
    static func eligibleGymGroups(from entries: [MuscleEntry],
                                  excluding excluded: Set<String> = [],   // for "give me another"
                                  restDays: Int = 1) -> [MuscleEntry] {
        return entries.filter { e in
            e.category == ActivityCategory.gym.rawValue && !e.isDeleted
            && !excluded.contains(e.name)
            // eligible if never trained or its last session was more than restDays ago
            // (use Date.appCalendar to compare by day)
        }
    }
}
```

End-to-end flow:
```
ContentViewModel.generateRoutine()
   → WorkoutEligibility.eligibleGymGroups(from: entries, excluding: ...)
   → MuscleCheckAI.suggestWorkout(eligible:)   // iOS 26 gated
   → RoutineSuggestion                         // cached + shown
```

**Fallback (important):** if **fewer than 2** remain eligible (you trained almost everything),
DON'T filter — use all gym groups (or the 2 most rested). Otherwise the model has nothing to pick
from.

---

## Step 2 — `MuscleCheckAI.suggestWorkout` (adjust what's there)

Today it passes **all** groups + history. Change it to receive **only the eligible ones** and
support exclusion.

```swift
// Suggested signature (RoutineSuggestion is the flat struct that already exists).
func suggestWorkout(eligible: [MuscleEntry]) async throws -> RoutineSuggestion
```

Inside:
1. Number ONLY the eligible groups (`0=Back, 1=Biceps, ...`).
2. Prompt = that list (no history — rotation is already solved).
3. `streamResponse(...)` (see Step 4) with `WorkoutSuggestion.self`.
4. Map `groupIndex → eligible[i].name`, drop out-of-range, **trim to 2**.
5. Return `RoutineSuggestion`.

**Schema tip (`@Guide` with `.count`):** instead of trusting the prompt for counts, pin them in
the schema. `@Guide` supports count constraints for arrays:
```swift
@Generable struct WorkoutSuggestion {
    @Guide(description: "...") var focus: String
    @Guide(description: "Exactly 2 coherent groups", .count(2)) var blocks: [WorkoutBlock]
    @Guide(description: "...") var rationale: String
}
@Generable struct WorkoutBlock {
    @Guide(description: "Index into the provided list") var groupIndex: Int
    @Guide(description: "3 exercises specific to that group", .count(3)) var exercises: [String]
}
```
This reduces the dependence on the prompt (the prompt alone didn't guarantee the count). Check
the exact `.count` syntax in the guided-generation doc linked above.

**Derive `focus` in code (optional, recommended):** the model sometimes returned an odd focus
("Legs" for biceps + triceps). Map the 2 chosen groups → "Push"/"Pull"/"Legs" yourself and
discard the model's `focus`.

---

## Step 3 — `LocalizedInstructions` (simplify to the winning version)

Replace `coachInstructions` with the **winning instruction** (Round 4) and `coachPrompt` with a
version **without history** (numbered list only). Exact text in
`docs/feature12-prompt-tuning.md`. The instruction must NO longer ask for rotation (that's code
now).

---

## Step 4 — Streaming for UX (`streamResponse`)

**Why:** showing the suggestion filling in progressively (focus → groups → exercises) feels
faster than a spinner.

**How:** `streamResponse(to:generating:)` returns an **AsyncSequence of snapshots**. The
`@Generable` macro generates `WorkoutSuggestion.PartiallyGenerated` (the same struct with every
property **optional**). Each snapshot is the partial state.

```swift
// Sketch.
let stream = session.streamResponse(to: prompt, generating: WorkoutSuggestion.self, options: opts)
for try await partial in stream {
    // partial.content: WorkoutSuggestion.PartiallyGenerated (optional properties)
    // publish what has arrived so the UI can paint it
}
// when the loop ends you have the full result → only then map indices + validate
```

**Design decision:** do the **index→entry mapping + validation** on the **final/complete**
snapshot (indices need complete data). During the stream you can show `focus`/`rationale`/names
as they appear, but the definitive `RoutineSuggestion` (the one you cache) is built at the end.

Docs: see WWDC "Deep dive" (streaming section) and the `LanguageModelSession` doc.

---

## Step 5 — `ContentViewModel`

- **New state:**
  ```swift
  @Published var routineSuggestion: RoutineSuggestion?   // RoutineSuggestion is already Codable
  @Published var isGeneratingRoutine = false
  private var lastSuggestedGroups: Set<String> = []      // for "give me another"
  ```
- **`generateRoutine(regenerate: Bool = false) async`** (gated `#available(iOS 26)`):
  1. `WorkoutEligibility.eligibleGymGroups(from: entries, excluding: regenerate ? lastSuggestedGroups : [])` (Step 1).
  2. `try await muscleCheckAI.suggestWorkout(eligible:)` (consuming the stream).
  3. Store in `routineSuggestion`, update `lastSuggestedGroups`, **cache** (Step 6).
  4. Handle errors → error state (localized string).
- **Remove the old path:** `reviewLastMonthWorkouts()` and `workoutSuggested`. The `import`/usage
  are already gated; when you delete them, update `ContentView` (Step 7).
- Remember `muscleCheckAI` is reached through the existing gated lazy accessor.

---

## Step 6 — Per-day cache (`UserDefaultsManager`)

**Why:** reopen the suggestion at the gym without regenerating.

- `RoutineSuggestion` is already `Codable`. Store the `Data` (JSON) + the date.
  ```swift
  var cachedRoutineData: Data?    // JSONEncoder().encode(routineSuggestion)
  var cachedRoutineDate: Date?
  ```
- In the ViewModel's `setup()`: if `cachedRoutineDate` is **today**
  (`Date.appCalendar.isDate(_:inSameDayAs:)`), decode it into `routineSuggestion`; otherwise it
  stays nil.
- No App Group needed unless you later want the suggestion in the widget.
- UserDefaults doc: https://developer.apple.com/documentation/foundation/userdefaults

---

## Step 7 — UI (`RoutineSuggestionView` + `ContentView`)

**`RoutineSuggestionView` (new, modal):**
- `focus` (title) + `rationale` + list of `blocks` (group name + its 3 exercises) + a **"Give me
  another"** button (calls `generateRoutine(regenerate: true)`) + close.
- Loading state while `isGeneratingRoutine` (or the progressive fill from streaming).
- **No "Add" button** — it's guidance only (the user checks in the main list as always).

**`ContentView`:**
- Replace the old "review" button/sheet with the new one.
- **Remove the Pro gate** (the feature is **free**): the block becomes just
  `if viewModel.isAppleIntelligenceAvailable() { button }` — without the
  `if storeManager.isPro { ... } else { ProFeatureGate }`.

---

## Step 8 — Strings (`Localizable.xcstrings`)
Add ES/EN/FR for: the modal's title/actions ("Give me another", close), the loading state, and the
generation error message. (The prompt/instruction texts already live in `LocalizedInstructions`,
not in xcstrings.)

---

## Step 9 — Cleanup
- **Delete `MuscleCheckTests/PromptExperiment.swift`** (temporary harness).

---

## Edge cases / gotchas
- **Fewer than 2 eligible** → fall back to all gym groups (Step 1). Test it by training
  "everything yesterday".
- **Model unavailable** (iOS < 26, unsupported hardware, AI off) → the button is already hidden
  via `isAppleIntelligenceAvailable()`. Don't touch that.
- **Exercise mislabeling** (biceps↔triceps): a known model residue, read-only, tolerable. Don't
  try to "fix" it with more prompt rules (it gets worse).
- **Cold start**: the first call can throw a transient error. The existing `prewarm` helps;
  consider calling it when the screen opens.
- **Unusual custom groups**: the model tends to ignore them and pick familiar ones. Known
  limitation (see findings); acceptable for v1.
- **Variety**: guaranteed by the "give me another" `exclude` (Steps 1/5), not by temperature
  alone.

## Testing
- The real output **can only be validated on device** (iOS 26 + Apple Intelligence), not in the
  simulator.
- The pure logic (Step 1: `eligibleGymGroups`, fallback, index mapping) **is testable** in the
  simulator with Swift Testing → worth covering (that's where the real intelligence lives).
