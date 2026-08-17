package com.zadkiel.musclecheck.domain.model

import androidx.annotation.StringRes
import com.zadkiel.musclecheck.R

/**
 * What a single exercise logs when checked, decided PER ENTRY (not per category —
 * the category only provides the default for new entries). Determines which fields
 * the session log sheet shows. Port of the iOS `MetricType` (same rawValues, so
 * entries created on either platform resolve identically).
 */
enum class MetricType(
    val id: String,
    @StringRes val displayNameRes: Int,
) {
    /** Check only — no session log. */
    NONE("none", R.string.metric_type_none),

    /** Weight + sets + reps (the original gym behavior). */
    STRENGTH("strength", R.string.metric_type_strength),

    /** Time only (plank, a yoga session). */
    DURATION("duration", R.string.metric_type_duration),

    /** Distance + time (running, cycling). */
    DISTANCE_DURATION("distanceDuration", R.string.metric_type_distance_duration);

    /** Whether opening the session log for this metric makes sense at all. */
    val logsSomething: Boolean get() = this != NONE

    companion object {
        fun fromId(id: String?): MetricType? = entries.firstOrNull { it.id == id }
    }
}

/**
 * Display formatting for session values. Single source for the metric labels shown
 * on home rows AND history rows, so separator/order/empty-handling can't drift.
 * Duration/distance are unit-invariant for v1 — minutes and km only, mirroring how
 * "kg"/"lbs" labels are literal.
 *
 * Pure (the unit is passed in, not read from prefs) so it stays JVM-testable, unlike
 * the iOS twin which reads UserDefaults directly.
 */
object SessionFormatting {

    /** "45 min" — whole minutes, storage is seconds. */
    fun formatDuration(seconds: Int): String = "${seconds / 60} min"

    /** "5.2 km" — one decimal, storage is meters. */
    fun formatDistance(meters: Double): String = String.format("%.1f km", meters / 1000)

    /** "20 kg" / "44 lbs" — whole numbers in the user's display unit; storage is kg. */
    fun formatWeight(kg: Double, unit: WeightUnit): String =
        String.format("%.0f", unit.displayValue(kg)) + " " + unit.displayLabel

    /**
     * The label for a set of session values under a given metric: "20 kg",
     * "45 min", "5.2 km · 32 min". Null when the metric logs nothing or no
     * relevant value is present.
     */
    fun label(
        metric: MetricType,
        weightKg: Double? = null,
        durationSeconds: Int? = null,
        distanceMeters: Double? = null,
        unit: WeightUnit = WeightUnit.KG,
    ): String? = when (metric) {
        MetricType.NONE -> null
        MetricType.STRENGTH -> weightKg?.let { formatWeight(it, unit) }
        MetricType.DURATION -> durationSeconds?.let { formatDuration(it) }
        MetricType.DISTANCE_DURATION -> {
            val parts = listOfNotNull(
                distanceMeters?.let { formatDistance(it) },
                durationSeconds?.let { formatDuration(it) },
            )
            parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
        }
    }
}
