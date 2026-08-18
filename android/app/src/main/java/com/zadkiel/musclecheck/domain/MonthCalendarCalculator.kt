package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WorkoutSession
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

/** One cell in the month grid; `isInDisplayedMonth` is false for adjacent-month spill days. */
data class CalendarDay(val date: LocalDate, val isInDisplayedMonth: Boolean)

/**
 * One trained group on a given day. Carries that day's group-level session plus any
 * exercises logged the same day, so the week detail can show per-exercise values
 * ("Peso muerto 100 kg") instead of a single number per group.
 */
data class DayActivity(
    val entry: MuscleEntry,
    val session: WorkoutSession?,
    val exercises: List<ExerciseOnDay> = emptyList(),
) {
    val weightKg: Double? get() = session?.weightKg
}

/** An exercise logged on a given day, with that day's values. */
data class ExerciseOnDay(val exercise: Exercise, val session: WorkoutSession)

/** The activities trained on a single day, used by the week detail breakdown. */
data class DayActivities(val date: LocalDate, val activities: List<DayActivity>)

/** Pure functions for the history month calendar. Monday-first, mirroring iOS. */
object MonthCalendarCalculator {

    /**
     * A fixed 6×7 matrix of days for the month containing [monthAnchor]. Always 42 cells
     * so the grid height never jumps when paging months.
     */
    fun monthMatrix(monthAnchor: LocalDate): List<List<CalendarDay>> {
        val month = YearMonth.from(monthAnchor)
        val gridStart = AppWeek.startOfWeek(month.atDay(1))
        val days = (0 until 42).map { offset ->
            val date = gridStart.plusDays(offset.toLong())
            CalendarDay(date = date, isInDisplayedMonth = YearMonth.from(date) == month)
        }
        return days.chunked(7)
    }

    /**
     * The 7 days (Monday-first) of the week containing [date], for the collapsed calendar.
     * `isInDisplayedMonth` is relative to [date]'s month.
     */
    fun weekRow(date: LocalDate): List<CalendarDay> {
        val monday = AppWeek.startOfWeek(date)
        val month = YearMonth.from(date)
        return (0 until 7).map { offset ->
            val day = monday.plusDays(offset.toLong())
            CalendarDay(date = day, isInDisplayedMonth = YearMonth.from(day) == month)
        }
    }

    /** Monday-first single-letter weekday headers, localized. */
    fun weekdaySymbols(locale: Locale = Locale.getDefault()): List<String> =
        (1..7).map { i ->
            java.time.DayOfWeek.of(i).getDisplayName(TextStyle.NARROW_STANDALONE, locale)
        }

    /** Set of dates that had at least one session (O(1) membership for the grid). */
    fun trainedDays(entries: List<MuscleEntry>): Set<LocalDate> =
        entries.asSequence().flatMap { it.sessions.asSequence() }.map { it.date }.toSet()

    /** Number of distinct muscles trained per day; drives the intensity of the calendar dot. */
    fun muscleCountByDay(entries: List<MuscleEntry>): Map<LocalDate, Int> {
        val counts = mutableMapOf<LocalDate, Int>()
        for (entry in entries) {
            for (day in entry.sessions.map { it.date }.distinct()) {
                counts[day] = (counts[day] ?: 0) + 1
            }
        }
        return counts
    }

    /** Count of unique days trained within the month containing [monthAnchor]. */
    fun trainedDayCount(monthAnchor: LocalDate, entries: List<MuscleEntry>): Int {
        val month = YearMonth.from(monthAnchor)
        return trainedDays(entries).count { YearMonth.from(it) == month }
    }

    /**
     * Per-day breakdown of the week containing [date]: only days with ≥1 activity,
     * ascending by date, entries sorted by name.
     */
    fun weekBreakdown(date: LocalDate, entries: List<MuscleEntry>): List<DayActivities> {
        val monday = AppWeek.startOfWeek(date)
        return (0 until 7).mapNotNull { offset ->
            val day = monday.plusDays(offset.toLong())
            val activities = entries
                .mapNotNull { entry ->
                    val session = entry.sessions.firstOrNull { it.date == day } ?: return@mapNotNull null
                    val exercises = entry.exercises.mapNotNull { exercise ->
                        exercise.sessions.firstOrNull { it.date == day }
                            ?.let { ExerciseOnDay(exercise, it) }
                    }
                    DayActivity(entry, session, exercises)
                }
                .sortedBy { it.entry.name }
            if (activities.isEmpty()) null else DayActivities(day, activities)
        }
    }
}
