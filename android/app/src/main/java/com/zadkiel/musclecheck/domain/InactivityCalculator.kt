package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.MuscleEntry
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Pure port of the iOS `NotificationManager` static helpers: which entries deserve
 * an inactivity reminder and what the single summary notification should say.
 */
object InactivityCalculator {

    /** Minimum full days without training before an entry is nagged about. */
    const val THRESHOLD_DAYS = 3

    data class Inactive(val entry: MuscleEntry, val days: Int)

    /**
     * Summary data for the single inactivity notification. The worker maps this to a
     * localized string at fire time (resources are not available in the pure domain).
     */
    data class Summary(
        val count: Int,
        val firstName: String,
        val firstDays: Int,
        val joinedNames: String,
    )

    /** Full days since the entry was last trained, or null if it was never trained. */
    fun daysInactive(entry: MuscleEntry, today: LocalDate = LocalDate.now()): Int? {
        val lastDay = entry.lastTrainedDate ?: return null
        return maxOf(0, ChronoUnit.DAYS.between(lastDay, today).toInt())
    }

    /**
     * Entries eligible for an inactivity reminder, most-inactive first.
     * Never-trained entries are excluded — nagging about an activity the user
     * hasn't even started is what caused the iOS 2.1.0 notification spam.
     */
    fun inactiveEntries(
        entries: List<MuscleEntry>,
        today: LocalDate = LocalDate.now(),
    ): List<Inactive> =
        entries
            .mapNotNull { entry -> daysInactive(entry, today)?.let { Inactive(entry, it) } }
            .filter { it.days >= THRESHOLD_DAYS }
            .sortedByDescending { it.days }

    /** Single summary covering every inactive entry, or null when there's nothing to say. */
    fun summary(inactive: List<Inactive>): Summary? {
        val first = inactive.firstOrNull() ?: return null
        val names = inactive.take(3).joinToString(", ") { it.entry.name }
        val suffix = if (inactive.size > 3) "…" else ""
        return Summary(
            count = inactive.size,
            firstName = first.entry.name,
            firstDays = first.days,
            joinedNames = names + suffix,
        )
    }
}
