package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.MuscleEntry
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

data class WeeklyCount(val weekLabel: String, val count: Int)
data class MuscleFrequency(val muscle: String, val count: Int)

/** Pure functions for the statistics screen. */
object StatsCalculator {

    /**
     * Count of unique training days per calendar week for the last [numberOfWeeks] weeks,
     * ordered oldest → newest.
     */
    fun daysTrainedPerWeek(
        entries: List<MuscleEntry>,
        numberOfWeeks: Int = 8,
        today: LocalDate = LocalDate.now(),
    ): List<WeeklyCount> {
        val currentWeekStart = AppWeek.startOfWeek(today)
        val formatter = DateTimeFormatter.ofPattern("MMM d", Locale.getDefault())

        return (-(numberOfWeeks - 1)..0).map { offset ->
            val weekStart = currentWeekStart.plusWeeks(offset.toLong())
            val weekEnd = weekStart.plusDays(6)
            val uniqueDays = entries.asSequence()
                .flatMap { it.sessions.asSequence() }
                .map { it.date }
                .filter { !it.isBefore(weekStart) && !it.isAfter(weekEnd) }
                .distinct()
                .count()
            WeeklyCount(weekLabel = formatter.format(weekStart), count = uniqueDays)
        }
    }

    /** Total unique training days per muscle, sorted by count descending. */
    fun frequencyByMuscle(entries: List<MuscleEntry>): List<MuscleFrequency> =
        entries
            .map { entry -> MuscleFrequency(entry.name, entry.sessions.map { it.date }.distinct().size) }
            .filter { it.count > 0 }
            .sortedByDescending { it.count }

    /** Total unique days trained across all history. */
    fun totalDaysTrained(entries: List<MuscleEntry>): Int =
        StreakCalculator.uniqueTrainingDays(entries).size

    /** Average unique training days per week over the last [numberOfWeeks] weeks. */
    fun averageTrainingDaysPerWeek(entries: List<MuscleEntry>, numberOfWeeks: Int = 8): Double {
        val weekly = daysTrainedPerWeek(entries, numberOfWeeks)
        if (weekly.isEmpty()) return 0.0
        return weekly.sumOf { it.count }.toDouble() / weekly.size
    }
}
