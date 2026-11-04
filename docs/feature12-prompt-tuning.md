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

## Implications for the code (not yet applied)
`MuscleCheckAI.suggestWorkout` (the current version passes all groups + history) needs to change:
- Filter eligible groups (exclude those trained in the last 1–2 days); pass only those.
- An `exclude: [String]` parameter for "give me another".
- Simplified instruction (the winner above); take rotation out of the prompt.
- Fallback: if fewer than 2 eligible groups remain, don't filter / use the most rested.
- Optional: derive `focus` in code from the 2 chosen groups (the model sometimes returns an odd
  focus).
- **UX: use `streamResponse` (not `respond`)** to show the suggestion as it generates (focus →
  groups → exercises) instead of a spinner. Better perceived speed.
