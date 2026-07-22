package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.MuscleEntry
import java.time.LocalDate

object StreakCalculator {

    /** Unique training days extracted from all entries' sessions, sorted descending. */
    fun uniqueTrainingDays(entries: List<MuscleEntry>): List<LocalDate> =
        entries.asSequence()
            .flatMap { it.sessions.asSequence() }
            .map { it.date }
            .distinct()
            .sortedDescending()
            .toList()

    /**
     * Start-of-week (Monday) dates that had ≥1 training day. The streak is measured in
     * WEEKS, not days — rest days are part of the plan and must not break the streak.
     */
    fun trainedWeeks(entries: List<MuscleEntry>): Set<LocalDate> =
        entries.asSequence()
            .flatMap { it.sessions.asSequence() }
            .map { AppWeek.startOfWeek(it.date) }
            .toSet()

    /**
     * Current streak in consecutive weeks with ≥1 training day, counting back from the
     * current week. Stays alive through the in-progress week: drops to 0 only once BOTH
     * this week and last week have no training.
     */
    fun currentStreak(entries: List<MuscleEntry>, today: LocalDate = LocalDate.now()): Int {
        val weeks = trainedWeeks(entries)
        if (weeks.isEmpty()) return 0

        val thisWeek = AppWeek.startOfWeek(today)
        val lastWeek = thisWeek.minusWeeks(1)

        var cursor = when {
            thisWeek in weeks -> thisWeek
            lastWeek in weeks -> lastWeek
            else -> return 0
        }

        var streak = 0
        while (cursor in weeks) {
            streak++
            cursor = cursor.minusWeeks(1)
        }
        return streak
    }

    /** Longest run of consecutive trained weeks across the whole history. */
    fun maxStreak(entries: List<MuscleEntry>): Int {
        val weeks = trainedWeeks(entries).sorted()
        if (weeks.isEmpty()) return 0

        var maxRun = 1
        var run = 1
        for (i in 1 until weeks.size) {
            if (weeks[i - 1].plusWeeks(1) == weeks[i]) {
                run++
                maxRun = maxOf(maxRun, run)
            } else {
                run = 1
            }
        }
        return maxRun
    }

    /** Last date the user trained, null if never. */
    fun lastTrainedDate(entries: List<MuscleEntry>): LocalDate? =
        uniqueTrainingDays(entries).firstOrNull()
}
