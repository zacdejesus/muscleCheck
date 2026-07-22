package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WorkoutSession
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant
import java.time.LocalDate

class CalculatorsTest {

    private var sessionId = 0

    private fun entry(name: String, vararg sessionDates: LocalDate, weights: List<Double?> = emptyList()): MuscleEntry {
        val today = LocalDate.now()
        return MuscleEntry(
            id = name,
            name = name,
            isChecked = false,
            weekOfYear = AppWeek.weekOfYear(today),
            year = AppWeek.weekBasedYear(today),
            dateCreated = Instant.now(),
            category = "gym",
            icon = "figure.strengthtraining.traditional",
            sessions = sessionDates.mapIndexed { i, date ->
                WorkoutSession(id = "s${sessionId++}", date = date, weightKg = weights.getOrNull(i))
            },
        )
    }

    // MARK: - AppWeek

    @Test
    fun `startOfWeek is Monday`() {
        // 2026-07-04 is a Saturday; its week starts Monday 2026-06-29.
        assertEquals(LocalDate.of(2026, 6, 29), AppWeek.startOfWeek(LocalDate.of(2026, 7, 4)))
        // A Monday maps to itself.
        assertEquals(LocalDate.of(2026, 6, 29), AppWeek.startOfWeek(LocalDate.of(2026, 6, 29)))
    }

    // MARK: - Streak

    @Test
    fun `no sessions means zero streak`() {
        assertEquals(0, StreakCalculator.currentStreak(listOf(entry("Pecho"))))
        assertEquals(0, StreakCalculator.maxStreak(listOf(entry("Pecho"))))
        assertNull(StreakCalculator.lastTrainedDate(listOf(entry("Pecho"))))
    }

    @Test
    fun `streak counts consecutive weeks and survives the grace week`() {
        val today = LocalDate.of(2026, 7, 4)
        val thisMonday = AppWeek.startOfWeek(today)
        // Trained last week and two weeks ago, nothing this week yet → grace keeps it at 2.
        val e = entry("Pecho", thisMonday.minusWeeks(1), thisMonday.minusWeeks(2))
        assertEquals(2, StreakCalculator.currentStreak(listOf(e), today))
    }

    @Test
    fun `streak dies after two empty weeks`() {
        val today = LocalDate.of(2026, 7, 4)
        val thisMonday = AppWeek.startOfWeek(today)
        val e = entry("Pecho", thisMonday.minusWeeks(2), thisMonday.minusWeeks(3))
        assertEquals(0, StreakCalculator.currentStreak(listOf(e), today))
        // But max streak still remembers the 2-week run.
        assertEquals(2, StreakCalculator.maxStreak(listOf(e)))
    }

    @Test
    fun `unique training days dedupe across entries`() {
        val day = LocalDate.of(2026, 7, 1)
        val entries = listOf(entry("Pecho", day), entry("Espalda", day, day.minusDays(1)))
        assertEquals(2, StatsCalculator.totalDaysTrained(entries))
    }

    // MARK: - Stats

    @Test
    fun `frequency by muscle sorts descending and drops zeros`() {
        val d = LocalDate.of(2026, 7, 1)
        val entries = listOf(
            entry("Pecho", d),
            entry("Espalda", d, d.minusDays(2), d.minusDays(4)),
            entry("Nunca"),
        )
        val freq = StatsCalculator.frequencyByMuscle(entries)
        assertEquals(listOf("Espalda" to 3, "Pecho" to 1), freq.map { it.muscle to it.count })
    }

    @Test
    fun `daysTrainedPerWeek returns 8 buckets oldest first`() {
        val today = LocalDate.of(2026, 7, 4)
        val entries = listOf(entry("Pecho", today, today.minusDays(1)))
        val weekly = StatsCalculator.daysTrainedPerWeek(entries, numberOfWeeks = 8, today = today)
        assertEquals(8, weekly.size)
        assertEquals(2, weekly.last().count)
        assertEquals(0, weekly.first().count)
    }

    // MARK: - Month calendar

    @Test
    fun `month matrix is always 6 weeks of 7 days starting Monday`() {
        val weeks = MonthCalendarCalculator.monthMatrix(LocalDate.of(2026, 7, 4))
        assertEquals(6, weeks.size)
        assertEquals(setOf(7), weeks.map { it.size }.toSet())
        // July 2026 starts Wednesday; grid starts the Monday before: June 29.
        assertEquals(LocalDate.of(2026, 6, 29), weeks.first().first().date)
        assertEquals(false, weeks.first().first().isInDisplayedMonth)
    }

    @Test
    fun `week breakdown includes only trained days with that day's weight`() {
        val monday = LocalDate.of(2026, 6, 29)
        val e = entry("Pecho", monday, monday.plusDays(2), weights = listOf(20.0, null))
        val breakdown = MonthCalendarCalculator.weekBreakdown(monday.plusDays(4), listOf(e))
        assertEquals(2, breakdown.size)
        assertEquals(20.0, breakdown[0].activities[0].weightKg)
        assertNull(breakdown[1].activities[0].weightKg)
    }

    @Test
    fun `muscle count by day counts distinct muscles`() {
        val day = LocalDate.of(2026, 7, 1)
        val entries = listOf(entry("Pecho", day), entry("Espalda", day))
        assertEquals(2, MonthCalendarCalculator.muscleCountByDay(entries)[day])
    }
}
