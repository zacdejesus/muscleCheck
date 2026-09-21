package com.zadkiel.musclecheck.analytics

import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import javax.inject.Inject

/**
 * The home screen's side of the activation funnel, kept out of `HomeViewModel` so it can be
 * tested without Room. Unscoped: each view model gets its own add-flow bookkeeping.
 */
class HomeAnalytics @Inject constructor(
    private val analytics: AnalyticsTracker,
    private val clock: AppOpenClock,
) {

    private data class Added(val category: String, val metric: MetricType, val fromPreset: Boolean)

    /** Entries added during the current opening of the add sheet, in order; null when closed. */
    private var addFlow: LinkedHashMap<String, Added>? = null

    /**
     * [before] is the entry as it was BEFORE the change: only "not trained → trained" this
     * week counts, so un-checking and re-logging an already trained group are not checks.
     */
    fun checked(before: MuscleEntry) {
        if (before.isChecked) return
        analytics.track(
            AnalyticsEvent.ActivityChecked(before.category, before.metric, clock.secondsSinceOpen())
        )
    }

    fun addStarted(source: AnalyticsEvent.AddSource) {
        addFlow = LinkedHashMap()
        analytics.track(AnalyticsEvent.ExerciseAddStarted(source))
    }

    fun entryAdded(id: String, category: String, metric: MetricType, fromPreset: Boolean) {
        addFlow?.put(id, Added(category, metric, fromPreset))
    }

    /** Undoing an add inside the sheet takes it back out of the count. */
    fun entryRemoved(id: String) {
        addFlow?.remove(id)
    }

    /**
     * One opening of the sheet = one attempt, counted on close with what stayed added.
     * Closing without adding anything is not an add.
     */
    fun addFinished() {
        val added = addFlow?.values?.toList().orEmpty()
        addFlow = null
        val last = added.lastOrNull() ?: return
        analytics.track(
            AnalyticsEvent.ExerciseAddCompleted(
                category = last.category,
                metric = last.metric,
                fromPreset = added.any { it.fromPreset },
                count = added.size,
            )
        )
    }
}
