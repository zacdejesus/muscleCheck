package com.zadkiel.musclecheck.analytics

import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.MetricType

/**
 * The Phase 1 events of docs/analytics-plan.md §8, typed. This is the ONLY place an event
 * becomes a name + parameters: a loose string at a call site is a typo that breaks nothing,
 * the data just never arrives. Names and parameters match the iOS `AnalyticsEvent` one to
 * one, because both platforms report into the same Firebase project: a name that drifts
 * splits one funnel into two.
 */
sealed interface AnalyticsEvent {
    val name: String

    /** Only String and Long (booleans travel as 0/1): what GA4 reports without surprises. */
    val parameters: Map<String, Any>

    /** Where the add screen was opened from: says whether the FAB is being found (§7.2). */
    enum class AddSource(val id: String) {
        FAB("fab"),
        EMPTY_STATE("empty_state"),
    }

    data object OnboardingStarted : AnalyticsEvent {
        override val name = "onboarding_started"
        override val parameters: Map<String, Any> = emptyMap()
    }

    /**
     * [seedCount]: how many disciplines built the starting list. [skipped] tells "picked" from
     * "skipped": by the count alone, skipping and picking only gym look the same.
     */
    data class OnboardingCompleted(val seedCount: Int, val skipped: Boolean) : AnalyticsEvent {
        override val name = "onboarding_completed"
        override val parameters: Map<String, Any>
            get() = mapOf("seed_count" to seedCount.toLong(), "skipped" to skipped.asLong())
    }

    /**
     * A group goes from "not trained" to "trained" this week. Logging something already
     * trained this week is not a new check. `source` is always `app`: Android has no Siri or
     * HealthKit path, but the parameter still travels so the iOS reports keep one shape.
     */
    data class ActivityChecked(
        val category: String,
        val metric: MetricType,
        val secondsSinceOpen: Long?,
    ) : AnalyticsEvent {
        override val name = "activity_checked"
        override val parameters: Map<String, Any>
            get() = buildMap {
                put("category", categoryParameter(category))
                put("metric", metric.id)
                put("source", "app")
                // Absent, not 0: a 0 would drag down the median that measures "2 seconds".
                secondsSinceOpen?.let { put("seconds_since_open", it) }
            }
    }

    data class ExerciseAddStarted(val source: AddSource) : AnalyticsEvent {
        override val name = "exercise_add_started"
        override val parameters: Map<String, Any>
            get() = mapOf("source" to source.id)
    }

    /**
     * One opening of the add screen that ended with at least one add. [category] and [metric]
     * are the last added entry's; [count] is how many stayed (undone ones don't count).
     */
    data class ExerciseAddCompleted(
        val category: String,
        val metric: MetricType,
        val fromPreset: Boolean,
        val count: Int,
    ) : AnalyticsEvent {
        override val name = "exercise_add_completed"
        override val parameters: Map<String, Any>
            get() = mapOf(
                "category" to categoryParameter(category),
                "metric" to metric.id,
                "from_preset" to fromPreset.asLong(),
                "count" to count.toLong(),
            )
    }

    companion object {
        /**
         * A custom category is stored as a UUID: sending it blows up cardinality and says
         * nothing, and its NAME is the user's free text (§10). Built-in → its id; anything
         * else → "custom".
         */
        fun categoryParameter(raw: String): String =
            (ActivityCategory.fromId(raw) ?: ActivityCategory.CUSTOM).id
    }
}

private fun Boolean.asLong(): Long = if (this) 1L else 0L
