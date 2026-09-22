# 🧱 Technical debt — refactor checklist

> Branch: `refactor/tech-debt` (from `main`). Review snapshot as of 2026-08-18, over `ios/`
> (~8,000 LOC) + the `android/` setup.
> Priorities in `CLAUDE.md` → Current focus.
>
> Ordered so each step leaves the ground cleaner for the next.
> Items 1–6 are mechanical and **don't touch persisted data**. Item 7 is the only one with a real
> migration, and it's best done **before** the release, while wiping the store is still a
> legitimate way out (zero users).
>
> Line numbers are from the original snapshot: item 5 is done and shifted everything below
> `ContentViewModel:100`.

---

## 0. ✅ Android keystore — closed

- [x] Rules in the **root** `.gitignore` (`:70-72`): `android/keystore.properties`, `*.jks`,
      `*.keystore`. They reached `main` with the signing commit (`db471bc`, PR #33).
- [x] `.jks` **outside the repo tree** → `~/Library/Mobile Documents/…/Documents/apps/`
      (iCloud Drive), with `storeFile` pointing to the absolute path.
- [x] Backup of the `.jks` + the 3 passwords off the laptop.

**Actual state:** the protection was implemented correctly from the start, in the root
`.gitignore`. The comment at `android/app/build.gradle.kts:11` saying *"is gitignored"* **is
correct** — nothing to fix there.

**The risk window is closed (2026-08-18).** It was narrow: the rules lived only in PR #33's
commit, so `main` — and any branch off main, like `refactor/tech-debt` — didn't have them, and
working from there a `git add -A` would have staged the credentials. It was closed by merging
#33 (`db471bc`, squash) and bringing `main` into the branch;
`git check-ignore -v android/keystore.properties` now answers `.gitignore:71` and the file is
gone from `git status`. `git log --all --full-history` confirms the credentials never entered
history — the only `*keystore*` match is `keystore.properties.example`, the template. Nothing to
purge.

> Process note: GitHub treated #33 as a *stacked PR* and rejected both `gh pr merge` and the
> classic `PUT /pulls/33/merge`. The async endpoint was needed
> (`PUT /repos/{owner}/{repo}/pulls/33/merge-async` + polling the UUID it returns).

⚠️ **Operational pending:** the `.jks` lives in iCloud Drive. With "Optimize Mac Storage" on,
macOS can evict it and leave a placeholder → `bundleRelease` fails with a keystore that is
"present" but empty. If it happens, open the folder in Finder to force the download, or keep a
local copy besides the iCloud one. As of 2026-08-18 the file is materialized on disk (2786
bytes, not a placeholder).

Keystore details (verified): valid until **2053**, RSA 2048, SHA384withRSA. Meets Play's
requirements (expiry ≥ 2033). **No need to regenerate it.** See the appendix at the end.

---

## 1. Delete dead code and contradictory rules

First, to shrink the surface before refactoring.

- [ ] `MuscleEntryManager.addDefaultEntries(names:)` (`:179`) — no callers, and it uses an
      **exact** name predicate while `addEntry` uses case-insensitive `normalizedName`
      (`:63-67`). Two definitions of "already exists" in the same class.
- [x] `MuscleEntryManager.toggleActivity(for:on:)` (`:162`) — duplicated
      `ContentViewModel.toggleActivity` with different semantics (no tips, no refresh).
      Deleted with item 4 (it wrote the flag). Same for `fetchEntries(forWeek:year:)` and the
      `MuscleEntryError.invalidWeekOrYear` case only it threw.
- [ ] `MuscleEntryManager.update(_:)` (`:143`) — ignores its parameter, only calls `save()`.
- [ ] `ContentViewModel.saveSession(_:for:)` (`:252`) — no callers since Phase 2; only two tests
      keep it alive (`ContentViewModelTests:100`, `:115`). Delete method + tests.
- [ ] `SessionLogView`: the `.none` case folded into `.strength`.
- [ ] Move `extension ModelContext: ModelContextProtocol {}` out of `ContentView.swift:311`
      (infrastructure conformance hidden in a view) into `ModelContextProtocol.swift`.

## 2. Non-optional `context` via init (two-phase init)

- [ ] Inject `ModelContextProtocol` through `init` in `ContentViewModel`; delete the optional
      `context` and `muscleEntryManager` (`:16-18`) and `setup(context:entries:)`.
- [ ] Remove the ~15 `context?.save()`.
- [ ] Review the errors swallowed today: `logHealthKitWorkout` does
      `guard let manager else { return }` (`:345`) and `catch { return }` (`:368-370`).

**Why:** with an optional field, any save before `setup()` is a **silent** no-op. `ContentView`
already has the `context` via `@Environment` before the first body, so the optionality buys
nothing.

## 3. ✅ Unify `@Query` vs ViewModel (double source of truth) — done for the list

- [x] Single owner: **`@Query`**. Grouping became a pure function (`ContentViewModel.group(_:)`)
      the view derives on every body; the `@Published` `weekEntries` and
      `groupedCurrentWeekEntries` are gone.
- [x] It stopped being tech debt: **it was the production crash**
      `MuscleEntry.exercisesSummary.getter` / EXC_BREAKPOINT. The cached list held references to
      entries deleted through other paths (`AddExerciseView.unadd()`), the home rendered them and
      SwiftData trapped when faulting `exercises`.
- [x] The defensive guard was ruled out **with evidence**, not opinion: `isDeleted` is `false`
      after a saved delete, and `modelContext` only becomes nil if the delete came from the same
      context. See `HomeStaleEntryTests`.
- [ ] The `updateCurrentEntries()` refetch remains: it no longer feeds the list, but still does
      `fetchAllEntries()` for the widget, the streak and the Crashlytics keys. It could take the
      `@Query` entries instead of re-querying.

**Verified along the way (pending from item 4):** the migration rehearsal was done with a store
written by the old schema (`db471bc`, with stored `isChecked`/`weekOfYear`/`year`) opened by the
current schema: **it opens fine and loses nothing** — entries, sessions and exercises intact.
SwiftData's implicit migration covers dropping those three attributes, so the store-wiping
fallback doesn't fire.

**Why:** today every tap on a check fires **two** pipelines over the same data: mutate →
`updateCurrentEntries()` (refetch + refilter + regroup + O(n²) streak + widget JSON), and in
parallel `@Query` invalidates itself → `onChange(of: entries)` (`:183`) →
`updateCurrentEntries()` **again**.

## 4. ✅ `isChecked` as a computed property (denormalization) — done

- [x] `isChecked` → `isTrained(inWeekOf: Date())`, over `sessions`. The comparison is asked of
      the calendar (`isDate(_:equalTo:toGranularity:.weekOfYear)`), not of components: a week
      straddling the new year has one week number and **two** calendar years, so comparing ints
      gives a false negative ~7 days a year.
- [x] Deleted `resetCheckedEntriesIfnewWeek()` and the `lastResetWeek`/`lastResetYear` flags.
- [x] `weekOfYear`/`year` out of the model. Gone with them: the weekly filter in
      `updateCurrentEntries` (which only worked because the reset re-stamped every entry) and
      `MuscleEntryManager.fetchEntries(forWeek:year:)`, which had no callers.
- [x] **Product decision:** unchecking = "I didn't train this this week" → deletes every session
      of the current week (`removeSessions(inWeekOf:)`). Deleting only the day's session left the
      check on if another session from the same week survived.
- [x] `WeeklyResetTip` kept with a new donor: the home compares this week's Monday against
      `UserDefaultsManager.lastSeenWeekStart` (**a `Date`**, not the pair of ints).
- [x] 18 new tests in `MuscleEntryWeekCheckTests` + a regression test for the Monday/Wednesday
      bug in `ContentViewModelTests`. Full suite: 229 tests green.

**Pending before merging:** removing 3 attributes from a `@Model` is a schema change — the
old store → new build rehearsal is still needed to know whether SwiftData migrates on its own or
falls into the wipe at `MuscleCheckApp.swift:75-88`.

**Open decision:** when unchecking a group's week, that week's sessions **inside
`Exercise.sessions`** stay. Today that's accidental behavior, not a decision.

**Why:** today there are 4 paths that keep both representations by hand and can drift apart:
`toggleActivity` (`:296-316`), `setTodaySession`, `logExercise`,
`MuscleEntryManager.toggleActivity`. As a computed property, the whole class of bug disappears
and the weekly reset stops existing as a concept.

## 5. ✅ Break up the `ContentViewModel` god object (374 lines, 7 responsibilities) — done

- [x] Extract the AI coach (`:22-102`, ~80 lines) into `RoutineCoachViewModel`. It shares nothing
      with the rest except `entries` — now passed as a parameter instead of stored, so there's no
      second copy of the list to keep in sync.
- [x] Extract the widget sync (`:193-206`) into a `WidgetBridge` **shared by both targets**:
      today the App Group `"group.zadkiel.musclecheck"` and the 3 `widget*` keys are hardcoded
      and duplicated in `ContentViewModel.swift:199-202` and `MuscleCheckWidget.swift:5-8`. A
      typo there breaks the widget silently.
- [x] Bonus: `SharedMuscleEntry` was duplicated in both targets. Now there's a single copy
      (`MuscleCheck/models/`), shared via `membershipExceptions` like the `.xcstrings`.

`ContentViewModel` went from 374 to 273 lines.

## 6. Performance of the pure calculators

- [ ] `StreakCalculator.uniqueTrainingDays` (`:19`) is O(n²) — a linear `contains` inside the
      loop.
- [ ] `StatsCalculator` uses `dayStart.description` as a `Set<String>` key (`:37`, `:58`).
      Formatting dates to strings to deduplicate is expensive and locale-fragile → `Set<Date>` of
      `startOfDay`.
- [ ] `MuscleEntry`: `lastWeight`/`lastSets`/`lastReps`/`lastDuration`/`lastDistance` are
      **5 independent scans** of the array, per row, per render. One scan returning the last
      relevant session.

## 7. `WorkoutSession` → `@Model` (the real scalability ceiling)

- [ ] `WorkoutSession` as a `@Model` with a real relationship to `MuscleEntry`.
- [ ] Same for the `sessions` nested inside `Exercise`.
- [ ] Add the model to `AppSchema.models`.
- [ ] Rewrite stats/streak/history with `#Predicate` by date range instead of full scans.

**Why:** today `sessions` and `exercises` are Codable blobs inside the row → **nothing is
queryable**. Every historical read is an in-memory full scan
(`StatsCalculator.daysTrainedPerWeek:33` iterates entries × sessions × 8 weeks) and grows without
a ceiling: 2 years × 7 groups × ~100 sessions + exercises inside get loaded whole to paint the
home.

**Risk:** it's the only real data migration on the list. The current strategy on schema mismatch
is to **wipe the store** (`MuscleCheckApp.swift:75-88`) — acceptable with zero users, not after
the release.

---

## Minor / follow-up

- [ ] `HistoryView.swift:10` — `StateObject(wrappedValue: HistoryViewModel.create(with: entries))`
      captures `entries` on first construction and never updates. Not visible today because the
      view is pushed fresh every time; it's a loaded trap.
- [ ] `UserDefaultsManager` — concrete singleton, 42 uses, **the only manager without a
      protocol**, precisely the one governing onboarding, weekly reset and the AI cache.
- [ ] `-resetOnboarding` bug (intra-suite order of `OnboardingUITests`): `MuscleCheckApp`
      bypasses the manager with raw `UserDefaults.standard` via strings (`:24-26`, `:40`),
      duplicating two keys the manager already defines. **The bypass is where the bug lives.**
      It fixes itself once the manager gets a protocol (previous item).

## Android

The domain duplication in Kotlin (`MonthCalendarCalculator`, `StreakCalculator`, models) is real
but **left alone**: KMP for two apps of a side project is ceremony that doesn't pay off. What
stays cheap to maintain is **test-suite parity** — the same edge cases existing on both sides is
what makes the duplication sustainable.

---

## Appendix — handling the Android keystore (for someone coming from iOS)

**The iOS mental model doesn't apply.** On iOS, if you lose the distribution certificate you
revoke it in the portal and generate another; Apple is the authority and the App Store re-signs
your app. On Android the key **is** the identity: there's no portal to revoke and reissue.

What saves the day is **Play App Signing** (mandatory for new apps since Aug 2021, so MuscleCheck
uses it no matter what). There are **two** keys:

| Key | Who holds it | If lost |
|---|---|---|
| **App signing key** — signs what users install | Google | You don't hold it: you can't lose it |
| **Upload key** — only proves to Play that the upload is yours (your `.jks`) | You | Recoverable: request a reset from Play support (takes days) |

So with Play App Signing, losing your `.jks` is **annoying, not fatal**. Without Play App Signing
(not our case) it would be fatal: you could never update the app again, and you'd have to publish
a new listing, losing installs and reviews.

Practical rules:

1. **Never in the repo** — neither the `.jks` nor `keystore.properties`. See item 0.
2. **Outside the repo tree** — today in `~/Library/Mobile Documents/…/Documents/apps/`
   (iCloud Drive), with `storeFile` as an absolute path. See the eviction warning in item 0.
3. **Backup in the password manager**, not just on the laptop: the `.jks` **and** the 3
   passwords (store, key, alias). The current alias is `musclecheck`.
4. **For CI**: never the file. Upload the `.jks` base64-encoded as a GitHub Actions secret, decode
   it in a step, and pass the passwords as separate secrets.
5. **The build already degrades gracefully**: without `keystore.properties`, `hasReleaseSigning`
   is false and the release builds unsigned (`android/app/build.gradle.kts:20`, signing branch).
   That keeps `bundleRelease` verifiable in CI without exposing anything.
