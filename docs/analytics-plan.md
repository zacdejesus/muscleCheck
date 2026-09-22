# 📊 Analytics plan — where users drop off

> Snapshot as of 2026-08-24. An explicit request from the developer, and at the time a
> **conscious exception to the "zero features"** of code-quality mode: this is
> instrumentation, not product. It doesn't change any screen.
>
> This doc is the **single source** of event names for iOS and Android. Defined once here,
> implemented twice. Same principle as test-suite parity.

---

## 0. The question

**At what point do people stop using MuscleCheck, and why?**

Everything that follows exists to answer that. The rule that governs the whole doc:

> **If an event doesn't answer a question we're already asking, it doesn't go in.**

We don't track "the clicks". Tracking clicks produces a lake of events nobody looks at and
that ages badly. We track a **funnel**, which is a hypothesis about where the experience
breaks.

---

## 1. Current state (audit)

| | State |
|---|---|
| **iOS** | `FirebaseApp.configure()` in `MuscleCheckApp.swift:34` and **nothing else**. Zero custom events. Only the automatic ones arrive: `first_open`, `session_start`, `screen_view`, `user_engagement`, `in_app_purchase` |
| **Android** | **Firebase doesn't exist.** No dependency, no Google Services plugin, no `google-services.json`. Half the users are invisible |
| **Monetization** | RevenueCat already gives the full funnel (paywall → purchase → churn) in its dashboard. **Don't duplicate** |
| **Config** | `ios/MuscleCheck/GoogleService-Info.plist` is **committed** (the `.gitignore` patterns stopped matching after the move to a monorepo). Android's `google-services.json` should follow the same policy: if it's ignored, the plugin **breaks the build** and CI goes down |

---

## 2. The measurement trap specific to this app

This is what a generic plan misses, and it's the most important part of the doc.

### 2.1 Product success means the user opens the app less

The positioning is *"track your workout in 2 seconds"*. There's a widget, App Intents/Siri and
HealthKit detection: **part of the usage happens outside the app**. A user who glances at the
widget, tells Siri "I trained chest" and never opens the app is a **maximum-success** user —
and on an opens dashboard they read as churn.

Design consequences, non-negotiable:

- The engagement metric is **"weeks with at least one check logged by any path"**, not opens or
  sessions.
- Every logging event carries a **`source`** parameter (`app` / `siri` / `healthkit`) to tell
  "doesn't use it" apart from "uses it without opening it".
- The widget is read-only today: tapping it opens the app, so it emits no events of its own.
  The App Intent can emit them, and **has to**, or Siri becomes a black hole.

### 2.2 Daily retention is the wrong metric

The app's mental model is a **weekly checklist**. Measuring D1/D7 will make it look dead,
because nobody *should* come in every day. The natural unit is the **ISO week** — which is also
what the domain already uses (`MuscleEntry.isTrained(inWeekOf:)`).

The public industry benchmarks are daily (§5). They are not compared naively against a weekly
app.

### 2.3 Without accounts, the identifier is per install

There's no login. The id is Firebase's app instance: **reinstall = new user**. That inflates
"new users" and breaks long retention curves. Accepted as a known limit; **we don't build auth
to fix the analytics**.

### 2.4 The denominators are biased

The AI coach is gated by iOS 26 + Apple Intelligence: for a share of users **the button doesn't
even exist**. Measuring `coach_opened / users` and concluding "nobody uses the AI" would be a
reading error, not a finding. That's why eligibility goes in as a **user property** (§9) and
every ratio is computed over the eligible population.

---

## 3. Framework: Goals → Signals → Metrics (HEART)

We use HEART (Google) because it separates what can be inferred from logs from what has to be
asked. Applied to MuscleCheck:

| | Goal | Signal | Metric | From logs? |
|---|---|---|---|---|
| **H**appiness | Logging feels effortless | Reviews, tester answers | Rating, qualitative feedback | ❌ Has to be asked |
| **E**ngagement | They log what they train | Checks per active week | Median checks/week | ✅ |
| **A**doption | They reach the first check | Install → first check | % checking within 24 h | ✅ |
| **R**etention | They come back next week | Consecutive weeks | % with ≥1 check in week 2 | ✅ |
| **T**ask success | They find how to add | Add opened → add saved | % of adds completed, time to the check | ✅ |

**Happiness is the only one that can't be inferred from logs.** If the plan doesn't include
talking to users (§13), that row stays empty forever.

---

## 4. North Star and the right unit of time

> **North Star: active weeks per user.**
> A week is active if the user logged ≥1 workout in it, by any path.

The nice part: **the product already computes its own North Star**. `StreakCalculator`'s weekly
streak is exactly this metric seen from the inside. Analytics just looks at it from the outside,
aggregated.

Habit-quality metric: the **streak distribution** (how many people reach 2, 4, 8, 12 weeks).
More honest than an average, which will be dominated by the tail of people who tried once.

---

## 5. Benchmarks (and why they barely apply yet)

Published ranges for health & fitness, useful as an order of magnitude:

- **D1** retention between ~20% and ~30–35%; the best reach ~45%.
- **D7** retention between ~7–8% and ~15–20%; top tier ~30%.
- **D30** retention between ~3% and ~8–12%; the best ~25%.
- Activation in fitness drops from ~26% on day 1 to ~10% by day 28.

Three caveats, in order of importance:

1. **They're daily.** Our model is weekly (§2.2). Comparing directly leads to false conclusions.
2. **The spread between sources is huge** (D1 from 20% to 35% depending on who measures). They
   tell us whether we're in a different order of magnitude, not what target to set.
3. **With the current user base they don't apply at all.** Five users don't make a percentage.

---

## 6. The activation funnel

The critical path, with an **explicit time window** — a funnel without a window completes
"eventually" and measures nothing:

```
install
  └→ onboarding_started
       └→ onboarding_completed            (or abandoned, with the step)
            └→ activity_checked  #1        ← ACTIVATION (window: 24 h)
                 └→ ≥1 check in week 2     ← HABIT (window: 14 days)
```

Also, **time to value is part of the product**: the promise is "2 seconds". That's why
`activity_checked` carries `seconds_since_open`. If the median is 8 seconds, the tagline is a
lie and that's a product bug, not an ugly number.

---

## 7. The five drop-off moments

Each with its hypothesis, the pair of events that measures it, and **what we'd do with the
answer**. If the last part is empty, the event isn't instrumented.

### 7.1 Onboarding → first check
- **Hypothesis:** the user picks their groups in onboarding and lands on a list they don't
  understand they're supposed to check.
- **Measures:** `onboarding_completed` → `activity_checked` (first).
- **Decision:** if the drop is high, onboarding needs to end *inside* the first check (the last
  step is checking something), not before it.

### 7.2 Adding exercises
- **Hypothesis:** it was already a real problem ("I can't find how to add") and it was fixed with
  the FAB in Feature 18. **There's no measurement of whether it worked.**
- **Measures:** `exercise_add_started` (with `source`: fab / empty_state) →
  `exercise_add_completed`.
- **Decision:** if abandonment is still high, the problem wasn't discovery but the form. If
  `source=empty_state` dominates, the FAB still isn't being seen.

### 7.3 Depth (Feature 19)
- **Hypothesis:** exercises inside a group were expensive to build; almost nobody may discover
  that tapping the name opens them.
- **Measures:** `group_detail_opened` over users with ≥1 group whose metric ≠ `none`.
- **Decision:** if it's marginal, the question isn't "how do we promote it" but whether the
  feature deserves to keep existing. A number like that **justifies deleting code**.

### 7.4 The second week
- **Hypothesis:** it's the big, structural drop of every habit app.
- **Measures:** install cohort → ≥1 check in week 2.
- **Decision:** it's what gives (or takes away) meaning from the reminder notification and the
  streak as a retention mechanic.

### 7.5 The AI coach
- **Hypothesis:** opened once out of curiosity and never again.
- **Measures:** `coach_opened` / `coach_regenerated`, **over the eligible population** (§2.4).
- **Decision:** if it's used once and never again, the problem is that it suggests without being
  able to act. If it's regenerated a lot, the first suggestion is bad.

### 7.6 The paywall — **not instrumented**
RevenueCat already has the whole monetization funnel. Duplicating it is work with the risk of
two numbers that don't match and nobody knows which to believe.

---

## 8. Event taxonomy

**Convention:** `object_action`, **past tense**, `snake_case`. **Events** say *what happened*;
**properties** say *who / where / how*. That separation is what prevents name explosion
(`add_from_fab`, `add_from_empty`… are one event with a parameter).

| Event | When | Parameters |
|---|---|---|
| `onboarding_started` | First screen of the first run | — |
| `onboarding_completed` | The flow ends (continue or skip) | `seed_count` (disciplines), `skipped` |
| ~~`onboarding_abandoned`~~ | *Dropped:* onboarding is a cover that can't be dismissed, so abandoning = killing the app. `started` without `completed` already measures it | — |
| `activity_checked` | A group's week goes from "not trained" to "trained", by any path. Re-logging in the same week doesn't count | `category` (built-in or `custom`), `metric`, `source`, `seconds_since_open` (only `source=app`) |
| `activity_unchecked` | Unchecked | `category` |
| `exercise_add_started` | The add screen opens | `source` (`fab`/`empty_state`/`category`) |
| `exercise_add_completed` | The add screen closes having added something (once per presentation) | `category` and `metric` of the last added, `from_preset`, `count` |
| `category_created` | A custom category is created | `metric` |
| `group_detail_opened` | A group's detail opens | `exercise_count_bucket` |
| `session_logged` | Values are saved | `metric`, `target` (`group`/`exercise`), `source` |
| `coach_opened` | The coach modal opens | `cached` |
| `coach_regenerated` | "Give me another" | — |
| `permission_result` | Answer to a permission | `type` (`notifications`/`healthkit`/`photos`), `granted` |
| `history_opened` | History opens | — |

**Fourteen.** If this list reaches thirty before there are users, something went wrong.

Lifecycle rule: **the event is deleted together with the feature that emits it.** Orphaned
events are how a taxonomy rots.

---

## 9. User properties (the denominators)

Not events: they're the axes any funnel gets segmented by.

| Property | Values | What for |
|---|---|---|
| `ai_available` | bool | The coach's honest denominator (§2.4) |
| `is_pro` | bool | Separate free/paid behavior |
| `entries_bucket` | `0` / `1-5` / `6-10` / `11+` | A user with 3 groups isn't comparable to one with 15 |
| `has_custom_categories` | bool | Did Feature 17 reach anyone? |
| `notifications_enabled` | bool | Denominator for the effect of reminders |
| `healthkit_enabled` | bool | Same, and it explains logs without an open |
| `weeks_since_install` | int | Cohorts |
| `app_language` | `es`/`en`/`fr`/`it` | If a localization performs differently, it's usually a copy bug |

---

## 10. What is NOT instrumented

- **User free text.** Exercise and custom category names can contain personal data and also blow
  up cardinality. The **category** and the **`MetricType`** go in, which are closed enums.
- **Any HealthKit content.** See §12: it's not a preference, it's an Apple rule.
- **`screen_view` for every screen.** Noise shaped like data.
- **Generic taps.** They don't answer any question from §7.
- **The purchase funnel.** It's already in RevenueCat.

---

## 11. Architecture

- **Our own seam**: `AnalyticsTracking` (protocol), shaped like `NotificationManagerProtocol` /
  `HealthKitManagerProtocol`. Firebase is *one* implementation. There's also a NoOp (tests and UI
  tests — UI tests **must not pollute the data**, and they already pass `-uiTesting` to disable
  TipKit: same hook) and one that logs to the console in debug.
  Implemented in `AnalyticsService.make`: `-uiTesting YES` → NoOp; Debug → console; Debug with
  `-analyticsDebug YES -FIRDebugEnabled` → Firebase + DebugView; Release → Firebase.
- **Typed events, never loose strings in views.** It's the `WidgetBridge` lesson: a literal
  duplicated in two places is a typo waiting to happen, and in analytics the typo **breaks
  nothing** — the data simply doesn't exist, and you find out three weeks later staring at an
  empty dashboard. The enum is also the only place that maps event → name + params, which is
  where the platform limits are enforced.
- **Fired from ViewModels**, not views. The VMs already have the domain verbs (`toggleActivity`,
  `addExercise`, `logExercise`, `generateRoutine`), so the event survives UI redesigns and is
  testable with a spy of the protocol. Legitimate exceptions: "I opened this screen" and "I
  abandoned this sheet", which are view facts.

**Firebase/GA4 limits to know before designing params:**

- 25 parameters per event **including the automatic ones** (~20 usable).
- Event name ≤ 40 characters; parameter names 1 to 40, starting with a letter.
- Custom parameters **don't show up in reports until registered as custom dimensions** (50
  available), and they must be registered **before** the event fires. Classic trap: you send the
  param, don't see it, and assume it isn't arriving.
- Reports take ~24 h. For development, use **DebugView**, which is real time. Don't confuse
  "didn't arrive" with "not processed yet".

**Android** needs: the `firebase-analytics` dependency, the Google Services plugin and
`google-services.json` (see the policy note in §1).

---

## 12. Privacy and compliance

- **HealthKit is non-negotiable.** Apple explicitly forbids sending HealthKit data to third
  parties, and using it for advertising or data mining. Sending workout content to Firebase would
  violate the guidelines and get rejected in review. We log the **fact** (`source=healthkit`),
  never the **payload**.
- **ATT/IDFA**: Firebase Analytics without IDFA doesn't require the ATT prompt. Explicitly
  disabling ad_id collection avoids the prompt entirely.
  **Done:** the target links only `FirebaseAnalyticsCore`, the product without IDFA support.
  `FirebaseAnalytics` was linked alongside it and was removed.
- **App Store privacy labels**: declare Usage Data → Product Interaction, not linked to identity.
- **Play Data safety**: same on the Android side. Fresh reminder: the app just came out of a
  policy violation; misdeclaring data collection is the cheapest way to get another one.

---

## 13. The qualitative complement (not optional)

With the current user base, **no dashboard will say anything statistically**. What you can do
with a small n:

- **Look for cliffs, not differences.** A drop from 100% to 20% shows with 5 users. A 5%
  improvement doesn't show even with 500. **No A/B tests.**
- **Five users in a moderated session uncover the vast majority of usability problems**
  (Nielsen). Twenty minutes with a tester give more signal than the whole dashboard for a month.
- The funnel works as a **conversation starter**: "I saw you opened the add screen three times
  and didn't save any — what happened there?".

Minimal script, tied to §7: install in front of you without help, reach the first check, add an
exercise, find yesterday's workout. Stay quiet and watch.

**Analytics doesn't replace this. It tells it where to look.**

---

## 14. Phases

- [x] **Phase 0 — this doc.** Names and params frozen before writing code.
- [x] **Phase 1 — iOS, activation only.** The seam + `onboarding_*`, `activity_checked`,
      `exercise_add_started/completed` (with `source` app/siri/healthkit). Shipped in 2.2.2;
      custom dimensions (`category`, `metric`, `source`, `seconds_since_open`, `seed_count`,
      `skipped`, `from_preset`, `count`) registered in the console.
- [ ] **Phase 2 — Android.** Firebase + the same events, verified against this doc.
      *Code done* in PR #44 (Analytics + Crashlytics, no ad ID; `source` is always `app`:
      Android has no Siri or HealthKit). **Pending, manual:** verify in DebugView (build with
      `-PanalyticsDebug` + `adb shell setprop debug.firebase.analytics.app com.zadkiel.musclecheck`),
      force a crash to see Crashlytics receive it, and fill in Play Data safety.
- [ ] **Phase 3 — the rest** of the §8 table and the §9 user properties.
- [ ] **Phase 4 — reading.** One funnel built in the console per §7 moment.
      BigQuery export only if SQL is needed (free on the daily tier).

---

## 15. How to read it

- **One funnel per week**, not a whole dashboard. Rotate among the five in §7.
- **Write the decision rule BEFORE looking at the number.** "If fewer than X% complete the add
  flow, we redesign the form." Without pre-registration, the number rationalizes itself.
- **The cohort rules.** Absolute metrics over a growing base are unreadable.

---

## 16. Risks

| Risk | Mitigation |
|---|---|
| Analytics as procrastination: instrumenting instead of talking to users | Phase 1 is small on purpose; §13 is not optional |
| Vanity metrics (opens, sessions) | §2.1 — the unit is the active week, not the open |
| Drift between platforms | This doc as the single source; names are reviewed in the PR |
| Instrumentation rot | The event is deleted with the feature that emits it (§8) |
| Over-reading numbers with a small n | §13 — cliffs yes, differences no |

---

## Sources

- [Health & Fitness App Benchmarks (2026) — Business of Apps](https://www.businessofapps.com/data/health-fitness-app-benchmarks/)
- [Mobile App Retention Benchmarks by Industry (2026) — UXCam](https://uxcam.com/blog/mobile-app-retention-benchmarks/)
- [Mobile App Retention Benchmarks 2026 — Snoopr](https://www.snoopr.co/blog/mobile-app-retention-benchmarks-2026-what-good-looks-like-for-fitness-ecommerce-gaming-and-more)
- [Event Taxonomy 101: The Object-Action Framework](https://productanalyticshandbook.com/blog/event-taxonomy-object-action/)
- [Best Practices When Creating or Evolving Your Analytics Tracking — Amplitude](https://amplitude.com/blog/analytics-tracking-practices)
- [Product Analytics: An Event Taxonomy That Won't Rot](https://www.digitalapplied.com/blog/product-analytics-event-taxonomy-tracking-plan-2026)
- [HEART framework: measuring UX with Google's metrics model — Statsig](https://www.statsig.com/perspectives/heart-framework-measuring-ux)
- [How to Set UX Metrics with the Google HEART Framework — The Fountain Institute](https://www.thefountaininstitute.com/blog/goals-signals-metrics)
- [[GA4] Event collection limits — Analytics Help](https://support.google.com/firebase/answer/9237506)
