# Feature 12 — AI Coach: prompt/instruction tuning findings

Results of tuning the coach's instructions/prompt against the **real on-device** model
(FoundationModels, iOS 26) on a **physical iPhone 15 Pro**. ~70 generations over 4 rounds
(2026-05-27). Harness: `MuscleCheckTests/PromptExperiment.swift` (temporary, delete when the
feature is closed).

## TL;DR — the conclusion that drives everything

**The model can NOT do rotation reliably. It has to be done in code.**
The on-device model (~3B) fails at reasoning over history. What works:

1. **Code filters the eligible groups** (excludes those trained in the last ~1–2 days) and passes
   the model **only those**.
2. **Code handles "give me another"**: also excludes what was just suggested → forces a different
   day (confirmed).
3. **The model does only the narrow part**: pick 2 coherent groups from the available ones + 3
   exercises each.

With the task this narrow, the model is **reliable**. When asked to reason (rotation), it failed.

## Winning instruction (Round 4)

Tested in Spanish, verbatim:

> Sos un entrenador de gimnasio. De la lista de grupos DISPONIBLES, elegí EXACTAMENTE 2 que formen
> un día coherente que se entrene junto (empuje: pecho/hombros/tríceps; tirón: espalda/bíceps;
> piernas: piernas/abdomen). Elegí por índice. Para CADA grupo dá 3 ejercicios que trabajen
> ESPECÍFICAMENTE ese músculo; nunca pongas ejercicios de otro grupo (ej: no pongas sentadillas en
> bíceps, ni curls en tríceps). Respondé en español.

In English:

> You are a gym coach. From the list of AVAILABLE groups, pick EXACTLY 2 that form a coherent day
> trained together (push: chest/shoulders/triceps; pull: back/biceps; legs: legs/abs). Pick by
> index. For EACH group give 3 exercises that work SPECIFICALLY that muscle; never put exercises
> from another group (e.g. no squats under biceps, no curls under triceps). Answer in Spanish.

**Prompt:** only the numbered available groups (no history — eligibility is already resolved in
code). `temperature 0.7`, `maximumResponseTokens 512`.

## What was tried and what happened

**Round 1 (3 variants, 1 input):** V1 (the one in the code) won; the concise and recovery-first
variants lost coherence. First hint: coherence has to be asked for explicitly.

**Round 2 (I1 vs I2-with-more-rules, 3 scenarios × 3 runs):**
- **Both failed rotation**: with "legs trained yesterday" they still suggested legs (3/3). Fixated
  on "Legs" (index 2).
- **I2 (more rules) came out WORSE**: it mixed exercises (deadlift under Shoulders, etc.). → more
  instructions = worse on a small model.

**Round 3 (simple instruction + 2 rotation-in-code strategies):**
- **A) exclusion in the prompt** ("don't recommend X"): sometimes violates the exclusion, still
  fixated on legs.
- **B) pass only eligible groups**: PUSH-yesterday → Legs + Abs 3/3, ALL 3/3. **Stable and
  coherent.** B won.

**Round 4 (strategy B + instruction refined for exercises):**
- Coherence ~8/12 clean (the rest borderline, like legs+back or antagonist push+pull).
- Variety improved (ALL no longer always gives legs; it gave Chest + Triceps).
- "Give me another" (exclude what was suggested) → gives a different day, confirmed 3/3.
- **Stubborn residue**: sometimes confuses biceps↔triceps in exercises. Read-only, tolerable.

**Round 5 (languages + new muscles, strategy B + winning instruction):**
- **Languages ES/EN/FR:** all three give coherent, localized output with correct exercises.
  Localized instructions/prompt are enough. No extra work.
- **New/unusual groups** (traps, forearms, calves, glutes, lower back): the model **drifts to the
  familiar** — it picked Chest + Back and ignored the unusual ones both times. Risk: users with
  granular custom groups may see the coach underuse them.
- **Vague/custom names** (upper body, core, arms): it **interprets them well** (lower body → legs,
  core → abs) and gives plausible content, but exercise mislabeling comes back more often (it put
  squats under "Core").
- Conclusion: multilingual OK. Heavy customization = two limits (bias to the familiar + more
  mislabeling). Acceptable for v1 (gym, default groups); document it.

## Observed model limitations (important for future AI features)
- Doesn't reason reliably over provided data (rotation, "don't repeat yesterday").
- Degrades with more complex instructions.
- Confuses the domain (exercises assigned to the wrong group).
- Anchoring/position bias (fixates on an index).
- Inconsistent run to run (hence temperature + variety in code).
- Cold-start hiccup ("server responded with an error" on the first call) → mitigated with a
  warmup.

**Good:** flawless structured output (`@Generable`), common knowledge on a narrow task,
multilingual, free / on-device / fast.

## Implications for the code (applied)
`MuscleCheckAI.suggestWorkout` (the current version passes all groups + history) needs to change:
- Filter eligible groups (exclude those trained in the last 1–2 days); pass only those.
- An `exclude: [String]` parameter for "give me another".
- Simplified instruction (the winner above); take rotation out of the prompt.
- Fallback: if fewer than 2 eligible groups remain, don't filter / use the most rested.
- Optional: derive `focus` in code from the 2 chosen groups (the model sometimes returns an odd
  focus).
- **UX: use `streamResponse` (not `respond`)** to show the suggestion as it generates (focus →
  groups → exercises) instead of a spinner. Better perceived speed.

## Private Cloud Compute (iOS 27) — 2026-10-30

iOS 27 opened Apple's server model to apps (`PrivateCloudComputeLanguageModel`: 32K context,
optional reasoning, free under 2M downloads, per-user daily quota, needs network). Question:
does it fix the on-device limits above? Harness on a physical iPhone 15 Pro, English unless
noted, 3 runs per scenario. Scenarios: push yesterday, legs yesterday, all fresh, unusual groups
(traps, forearms, calves…), custom names ("Upper body", "Core"…), groups named
"Push/Pull/Legs", combined groups ("Chest & triceps").

### What was tried

| Variant | Correct (coherent pair, right exercises) | Total latency | Notes |
|---|---|---|---|
| On-device (shipped) | 6/15 | 2.7–5.5 s | Chest exercises under "Back", pull-ups under "Core", generic rationale |
| **PCC-A**: same narrow prompt | **15/15** | **1.7–1.9 s** | Faster than on-device; rotation still in code |
| PCC-B: all groups + history, model rotates, `.light` reasoning | 10/10 answered | 10–117 s | **5/15 empty responses**. Rejected |
| On-device + history | — | — | 6/15 failed on guardrails ("May contain sensitive content"), rest still wrong. Rejected |
| PCC-A+H v1: A + last-4-weeks history as a preference | 9/15 | 1.8–2.0 s | Real rationale ("6 days ago, 1 session"), but on unusual/custom groups "least trained" beat coherence |
| v2: coherence first, history only as a tie-breaker | 7/9 | 1.7–2.3 s | Fixed unusual; custom names got leg exercises under "Upper body" |
| v3: v2 + schema copies the group's name before its exercises | 15/15 exercises right | 1.8–2.3 s | Name echo anchors exercises to the picked group |
| v3b: v3 + instructions for free-form names | — | — | Used history less, less consistent. More instructions didn't help, again |
| **v4 (shipped)**: v3 with `focus` generated after the groups | 0/42 wrong exercises (EN+ES) | 1.4–3.3 s | Labels describe the pick. 9/42 weak pairs on unusual/combined groups |

### Shipped: v4 on PCC, today's path on-device as fallback
- Rotation stays in code (`WorkoutEligibility`) for both engines: a guarantee, needed by the
  fallback, and free.
- PCC gets the eligible groups + their history (`CoachHistory`), answers whole (`respond`, not
  streaming) within 6 s, and blocks whose copied name disagrees with their index are dropped
  (`echoedNameMatches`).
- Anything else falls back to the unchanged on-device path; the reason goes to analytics
  (`coach_generated`).
- Through the app's own path: ES 7/7 PCC (2.1–4.5 s), IT 14/14 (1.9–3.5 s), FR 14/14
  (1.9–2.8 s).

### Lessons
- **A bigger model fixed the knowledge errors, not the reasoning ones for free.** PCC-A was
  perfect at picking pairs and exercises; reasoning over history (B) was slow and flaky. Rules
  stay in code; the model gets judgment.
- **Schema order is a prompt.** `@Generable` fields generate in declaration order: copying the
  group's name before its exercises ended mismatches, and generating `focus` last stopped the
  label from steering the pick.
- **Every new rule moves the failure.** Each A+H version fixed one scenario and broke another;
  v4 stopped there and ships with known weak pairs.
- **The echo isn't clean text.** The model copied "Legs: legs/abs" and "Core: 9 days ago; 1", so
  the name check tolerates trailing noise.
- **The rationale leaked indices** ("groups 0 and 2") until told to name the groups.
- **Quota:** after ~250 PCC calls in one day the status stayed `belowLimit`, not even
  approaching.

### Known limitations
- On groups that are all unusual or bundled, the history can still pick a weak pair (correct
  exercises, honest label). Revisit with real usage data from `coach_generated`.
- The rationale can misread the history: one FR run said chest and shoulders had fewer
  sessions than back and biceps, the other way round. The pair itself was valid.
- Only EN and ES were tuned; FR and IT were smoke-tested.

## On-device, revisited with PCC's lessons — 2026-11-23

The on-device path is the fallback whenever PCC isn't used, and it had never had the schema
changes that fixed PCC. Harness: the coach's prompts, schemas, options and checks copied into a
Swift package and run under `swift test` on a Mac (macOS 27.2.1, on-device model assets
`16.1000.0.13.103404`), through the app's streaming path at the app's options (random sampling,
temperature 0.7), 5 samples per case. Not yet checked on an iPhone.

Scoring is in code: "coherent" from the instructions' push/pull/legs table (lists with free-form
or combined names aren't scorable), "right group" by keywords (shoulder exercises under chest,
leg exercises under upper-body groups). An on-device model judge was tried and rejected: it
failed 13–15 of 30 in every variant, with confused rationales.

**Round 1: schema order (6 lists, 30 samples).** PCC's order on-device: each block copies its
group's name before the exercises, the focus comes after the groups, and blocks whose name
disagrees with their index are dropped.

| Variant | Two valid groups | Exercises under the right group |
|---|---|---|
| Shipped | 25/30 | 10/30 |
| PCC's schema order | 30/30 | 30/30 |

It fixed both shipped failures: overhead press and lateral raises under Chest/Pecho in every
sample of those lists, and with custom names one index picked twice ("Upper body" for both
blocks, 5/5), which the app showed as a one-group day.

**Round 2: the model never picks legs.** With a legs pair available it chose push 45/45. Eight
runs to separate the causes (`Chest, Shoulders, Triceps, Legs, Abs` unless noted):

| Run | Picks (5 samples) |
|---|---|
| As listed | push 5/5 |
| List reversed (Legs, Abs first) | push 5/5 — position isn't it |
| Instructions' table with legs first | Legs + Abs 5/5 |
| Table legs first, list reversed | Legs 5/5, paired with a push group 3/5 |
| No push groups (`Back, Biceps, Legs, Abs`) | Back 5/5, Back + Abs 4/5 |
| Spanish / greedy | push 4/5 / 5/5 |

**The model doesn't choose a day: it takes the first day of the instructions' table that has
groups**, and when that day has one group it pairs across days. In the app this beats rotation:
with chest trained yesterday, shoulders and triceps remain and the coach says push again.

**Round 3: the day chosen in code (9 lists after the rotation filter, 45 samples).**
`WorkoutEligibility.groupsForToday` picks the day of the most rested group whose day has at
least 2 groups, and the model only gets that day's groups. Lists: all fresh, legs most rested,
pull most rested, no push (EN and ES), unusual groups, combined names, custom names.

| Variant | Two valid groups | Coherent pair | Right group | Most rested day |
|---|---|---|---|---|
| Model chooses the day | 45/45 | 22/35 | 42/45 | never legs, 0/10 |
| **Day chosen in code (shipped)** | 43/45 | 38/38 | 43/45 | always |

Lessons:
- **Schema order transfers between models.** The same change fixed the same errors on the 3B
  on-device model as on PCC.
- **An example in the instructions is a default.** "(push: …; pull: …; legs: …)" was meant as
  a table and read as a ranking.
- **Again a rule in code.** The day joins rotation: what code can decide, the model isn't asked.

Known limitations:
- A day with exactly two groups sometimes gets one of them twice ("Legs and Legs", 2/45). The
  app shows the one valid group, as before.
- The focus label can name another day ("Push and Legs day" over Legs + Abs, 6/40). Deriving it
  in code from the day is a possible next step (it needs localized strings).
- Free-form and combined names have no day: lists made only of them behave as before.
- PCC still chooses its own day; it wasn't measured for this bias (it can't be called from the
  command line).
