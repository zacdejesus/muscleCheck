package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WorkoutSession
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDate

/** Port of the iOS NotificationManagerTests — the spec for inactivity reminder semantics. */
class InactivityCalculatorTest {

    private val today: LocalDate = LocalDate.of(2026, 7, 10)
    private var sessionId = 0

    private fun entry(name: String, vararg daysAgo: Long): MuscleEntry = MuscleEntry(
        id = name,
        name = name,
        isChecked = false,
        weekOfYear = AppWeek.weekOfYear(today),
        year = AppWeek.weekBasedYear(today),
        dateCreated = Instant.now(),
        category = "gym",
        icon = "figure.strengthtraining.traditional",
        sessions = daysAgo.map {
            WorkoutSession(id = "s${sessionId++}", date = today.minusDays(it))
        },
    )

    // MARK: - daysInactive

    @Test
    fun `never trained has no inactivity`() {
        assertNull(InactivityCalculator.daysInactive(entry("Chest"), today))
    }

    @Test
    fun `trained today is zero days inactive`() {
        assertEquals(0, InactivityCalculator.daysInactive(entry("Chest", 0), today))
    }

    @Test
    fun `trained three days ago is three days inactive`() {
        assertEquals(3, InactivityCalculator.daysInactive(entry("Chest", 3), today))
    }

    @Test
    fun `uses most recent session across multiple`() {
        assertEquals(1, InactivityCalculator.daysInactive(entry("Chest", 5, 1, 3), today))
    }

    // MARK: - inactiveEntries (summary eligibility)

    @Test
    fun `never trained entries are excluded`() {
        val result = InactivityCalculator.inactiveEntries(
            listOf(entry("Never"), entry("Trained", 4)),
            today,
        )
        assertEquals(listOf("Trained"), result.map { it.entry.name })
    }

    @Test
    fun `two days inactive is not eligible, three is`() {
        val result = InactivityCalculator.inactiveEntries(
            listOf(entry("Recent", 2), entry("Stale", 3)),
            today,
        )
        assertEquals(listOf("Stale"), result.map { it.entry.name })
    }

    @Test
    fun `sorted most inactive first`() {
        val result = InactivityCalculator.inactiveEntries(
            listOf(entry("A", 3), entry("B", 7), entry("C", 5)),
            today,
        )
        assertEquals(listOf("B", "C", "A"), result.map { it.entry.name })
        assertEquals(listOf(7, 5, 3), result.map { it.days })
    }

    // MARK: - summary (single notification body)

    @Test
    fun `empty list produces no summary`() {
        assertNull(InactivityCalculator.summary(emptyList()))
    }

    @Test
    fun `single entry summary carries name and days`() {
        val inactive = InactivityCalculator.inactiveEntries(listOf(entry("Espalda", 5)), today)
        val summary = InactivityCalculator.summary(inactive)!!
        assertEquals(1, summary.count)
        assertEquals("Espalda", summary.firstName)
        assertEquals(5, summary.firstDays)
    }

    @Test
    fun `multiple entries joined most inactive first`() {
        val inactive = InactivityCalculator.inactiveEntries(
            listOf(entry("Pecho", 3), entry("Piernas", 6)),
            today,
        )
        val summary = InactivityCalculator.summary(inactive)!!
        assertEquals(2, summary.count)
        assertEquals("Piernas, Pecho", summary.joinedNames)
    }

    @Test
    fun `more than three entries truncates names with ellipsis`() {
        val inactive = InactivityCalculator.inactiveEntries(
            listOf(entry("A", 3), entry("B", 4), entry("C", 5), entry("D", 6)),
            today,
        )
        val summary = InactivityCalculator.summary(inactive)!!
        assertEquals(4, summary.count)
        assertEquals("D, C, B…", summary.joinedNames)
        assertTrue(summary.joinedNames.endsWith("…"))
    }
}
