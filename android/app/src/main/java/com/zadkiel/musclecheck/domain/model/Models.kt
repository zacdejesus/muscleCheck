package com.zadkiel.musclecheck.domain.model

import java.time.Instant
import java.time.LocalDate

/**
 * One logged session. Weight is ALWAYS stored in kg, distance in meters, duration in
 * seconds (canonical units); conversion happens at the UI edges.
 */
data class WorkoutSession(
    val id: String,
    val date: LocalDate,
    val weightKg: Double? = null,
    val sets: Int? = null,
    val reps: Int? = null,
    val durationSeconds: Int? = null,
    val distanceMeters: Double? = null,
)

/** Everything the session-log sheet can capture in one save, in canonical units. */
data class SessionInput(
    val weightKg: Double? = null,
    val sets: Int? = null,
    val reps: Int? = null,
    val durationSeconds: Int? = null,
    val distanceMeters: Double? = null,
)

/** A progress photo. The image is on disk (`fileName` under the app's photos dir);
 *  this only carries metadata. */
data class ProgressPhoto(
    val id: String,
    val date: LocalDate,
    val fileName: String,
)

/**
 * A named exercise inside a group (e.g. "Peso muerto" under "Piernas"), each with its
 * own metric and value history. The group keeps its own `sessions` for the WEEKLY
 * CHECK / date semantics (streak, stats, notifications all read those) — exercises are
 * a DETAIL layer. Logging an exercise also marks the group trained that day.
 */
data class Exercise(
    val id: String,
    val name: String,
    val icon: String,
    /** Raw [MetricType] id. Each exercise logs its OWN thing, independent of the group. */
    val metricRaw: String,
    val sessions: List<WorkoutSession> = emptyList(),
) {
    val metric: MetricType get() = MetricType.fromId(metricRaw) ?: MetricType.STRENGTH

    /** Most recent session for which [value] is non-null — single scan. */
    private fun <T> latestValue(value: (WorkoutSession) -> T?): T? {
        var best: Pair<LocalDate, T>? = null
        for (session in sessions) {
            val v = value(session) ?: continue
            if (best == null || session.date > best.first) best = session.date to v
        }
        return best?.second
    }

    val lastWeightKg: Double? get() = latestValue { it.weightKg }
    val lastSets: Int? get() = latestValue { it.sets }
    val lastReps: Int? get() = latestValue { it.reps }
    val lastDurationSeconds: Int? get() = latestValue { it.durationSeconds }
    val lastDistanceMeters: Double? get() = latestValue { it.distanceMeters }

    /**
     * Most recent session recording distance OR duration — read BOTH values from this
     * one session so a distance from one day and a time from another aren't paired as
     * if they had been done together.
     */
    val lastDistanceDurationSession: WorkoutSession?
        get() = sessions.filter { it.distanceMeters != null || it.durationSeconds != null }
            .maxByOrNull { it.date }

    val lastTrainedDate: LocalDate? get() = sessions.maxOfOrNull { it.date }

    /** Row label for this exercise under the group ("100 kg", "45 min", "5.2 km · 32 min"). */
    fun summary(unit: WeightUnit): String? = SessionFormatting.label(
        metric = metric,
        weightKg = lastWeightKg,
        durationSeconds = if (metric == MetricType.DISTANCE_DURATION) {
            lastDistanceDurationSession?.durationSeconds
        } else {
            lastDurationSeconds
        },
        distanceMeters = lastDistanceDurationSession?.distanceMeters,
        unit = unit,
    )
}

/** Domain mirror of the iOS `MuscleEntry` SwiftData model. */
data class MuscleEntry(
    val id: String,
    val name: String,
    val isChecked: Boolean,
    val weekOfYear: Int,
    val year: Int,
    val dateCreated: Instant,
    val category: String,
    val icon: String,
    val sessions: List<WorkoutSession> = emptyList(),
    /**
     * Raw [MetricType] id. Empty string = pre-metric entry, resolved lazily from the
     * category (and persisted by the startup backfill) — the same additive-migration
     * trick iOS uses, so entries created before this feature keep working.
     */
    val metricRaw: String = "",
    val exercises: List<Exercise> = emptyList(),
) {
    /** Most recent recorded weight (kg), looking back across sessions. Null if never recorded. */
    val lastWeightKg: Double?
        get() = sessions.sortedByDescending { it.date }.firstOrNull { it.weightKg != null }?.weightKg

    val lastSets: Int?
        get() = sessions.sortedByDescending { it.date }.firstOrNull { it.sets != null }?.sets

    val lastReps: Int?
        get() = sessions.sortedByDescending { it.date }.firstOrNull { it.reps != null }?.reps

    val lastTrainedDate: LocalDate?
        get() = sessions.maxOfOrNull { it.date }

    /**
     * This group's metric. Falls back to the built-in category's default for entries
     * created before metrics existed; custom categories need the resolver, so callers
     * holding custom categories should use [metricResolving].
     */
    val metric: MetricType
        get() = MetricType.fromId(metricRaw)
            ?: ActivityCategory.fromId(category)?.defaultMetric
            ?: MetricType.NONE

    /** [metric], but able to fall back to a CUSTOM category's default too. */
    fun metricResolving(customCategories: List<CustomCategory>): MetricType =
        MetricType.fromId(metricRaw)
            ?: ActivityCategory.fromId(category)?.defaultMetric
            ?: customCategories.firstOrNull { it.id == category }?.defaultMetric
            ?: MetricType.NONE

    /**
     * Row label under the group name. With exercises: count + the most recently logged
     * one. Without exercises, falls back to the group's own single-value label so
     * nothing regresses for entries that never used the detail layer.
     */
    fun summary(unit: WeightUnit): EntrySummary? {
        if (exercises.isEmpty()) {
            val own = SessionFormatting.label(metric = metric, weightKg = lastWeightKg, unit = unit)
            return own?.let { EntrySummary(exerciseCount = 0, ownLabel = it) }
        }
        val recent = exercises.maxByOrNull { it.lastTrainedDate ?: LocalDate.MIN }
        val value = recent?.summary(unit)
        return EntrySummary(
            exerciseCount = exercises.size,
            recentName = if (value != null) recent.name else null,
            recentValue = value,
        )
    }
}

/**
 * Pieces of a group's row label. The UI assembles the final string because the
 * "N exercises" part needs a plural resource, which is a platform concern.
 */
data class EntrySummary(
    val exerciseCount: Int,
    val recentName: String? = null,
    val recentValue: String? = null,
    val ownLabel: String? = null,
)

/** A category the user creates beyond the built-in [ActivityCategory] cases. */
data class CustomCategory(
    val id: String,
    val name: String,
    val icon: String,
    val sortOrder: Int,
    /**
     * Legacy Feature-17 flag, kept as the migration source for [defaultMetricRaw] on
     * categories created before per-exercise metrics existed.
     */
    val tracksWeight: Boolean,
    val defaultMetricRaw: String = "",
) {
    /** Default metric for new entries in this category. */
    val defaultMetric: MetricType
        get() = MetricType.fromId(defaultMetricRaw)
            ?: if (tracksWeight) MetricType.STRENGTH else MetricType.NONE
}

/** User preference for weight display. Storage is always kg. */
enum class WeightUnit(val id: String, val displayLabel: String) {
    KG("kg", "kg"),
    LBS("lbs", "lbs");

    fun displayValue(fromKg: Double): Double = when (this) {
        KG -> fromKg
        LBS -> fromKg * 2.20462
    }

    fun toKg(value: Double): Double = when (this) {
        KG -> value
        LBS -> value / 2.20462
    }

    companion object {
        fun fromId(id: String?): WeightUnit = entries.firstOrNull { it.id == id } ?: KG
    }
}
