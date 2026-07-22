package com.zadkiel.musclecheck.domain.model

import java.time.Instant
import java.time.LocalDate

/** One logged session. Weight is ALWAYS stored in kg; conversion happens at the UI edges. */
data class WorkoutSession(
    val id: String,
    val date: LocalDate,
    val weightKg: Double? = null,
    val sets: Int? = null,
    val reps: Int? = null,
)

/** A progress photo. The image is on disk (`fileName` under the app's photos dir);
 *  this only carries metadata. */
data class ProgressPhoto(
    val id: String,
    val date: LocalDate,
    val fileName: String,
)

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
}

/** A category the user creates beyond the built-in `ActivityCategory` cases. */
data class CustomCategory(
    val id: String,
    val name: String,
    val icon: String,
    val sortOrder: Int,
    val tracksWeight: Boolean,
)

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
