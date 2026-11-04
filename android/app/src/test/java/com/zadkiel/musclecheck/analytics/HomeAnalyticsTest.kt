package com.zadkiel.musclecheck.analytics

import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class HomeAnalyticsTest {

    private class SpyAnalytics : AnalyticsTracker {
        val events = mutableListOf<AnalyticsEvent>()
        override fun track(event: AnalyticsEvent) {
            events += event
        }
    }

    private val spy = SpyAnalytics()
    private val clock = AppOpenClock()
    private val analytics = HomeAnalytics(spy, clock)

    private fun entry(checked: Boolean, category: String = "gym", metricRaw: String = "strength") = MuscleEntry(
        id = "e1",
        name = "Chest",
        isChecked = checked,
        weekOfYear = 1,
        year = 2026,
        dateCreated = Instant.EPOCH,
        category = category,
        icon = "",
        metricRaw = metricRaw,
    )

    @Test
    fun `checking an untrained group is a check, with the time since open`() {
        val opened = Instant.parse("2026-09-21T10:00:00Z")
        clock.markOpened(opened)

        analytics.checked(before = entry(checked = false))

        val event = spy.events.single() as AnalyticsEvent.ActivityChecked
        assertEquals(MetricType.STRENGTH, event.metric)
        assertTrue(event.secondsSinceOpen!! >= 0)
    }

    @Test
    fun `an already trained group is not a new check`() {
        analytics.checked(before = entry(checked = true))

        assertTrue(spy.events.isEmpty())
    }

    @Test
    fun `no recorded open leaves the time out`() {
        analytics.checked(before = entry(checked = false))

        assertNull((spy.events.single() as AnalyticsEvent.ActivityChecked).secondsSinceOpen)
    }

    @Test
    fun `clock never reports negative time`() {
        val now = Instant.parse("2026-09-21T10:00:00Z")
        clock.markOpened(now.plusSeconds(5))

        assertEquals(0L, clock.secondsSinceOpen(now))
    }

    @Test
    fun `closing the sheet counts what stayed added`() {
        analytics.addStarted(AnalyticsEvent.AddSource.FAB)
        analytics.entryAdded("a", "gym", MetricType.STRENGTH, fromPreset = true)
        analytics.entryAdded("b", "gym", MetricType.STRENGTH, fromPreset = true)
        analytics.entryAdded("c", "yoga", MetricType.DURATION, fromPreset = false)
        analytics.entryRemoved("b")
        analytics.addFinished()

        assertEquals(AnalyticsEvent.ExerciseAddStarted(AnalyticsEvent.AddSource.FAB), spy.events.first())
        assertEquals(
            AnalyticsEvent.ExerciseAddCompleted("yoga", MetricType.DURATION, fromPreset = true, count = 2),
            spy.events.last(),
        )
    }

    @Test
    fun `closing without adding is not an add`() {
        analytics.addStarted(AnalyticsEvent.AddSource.EMPTY_STATE)
        analytics.entryAdded("a", "gym", MetricType.STRENGTH, fromPreset = true)
        analytics.entryRemoved("a")
        analytics.addFinished()

        assertEquals(1, spy.events.size)
    }

    @Test
    fun `each opening of the sheet counts on its own`() {
        analytics.addStarted(AnalyticsEvent.AddSource.FAB)
        analytics.entryAdded("a", "gym", MetricType.STRENGTH, fromPreset = false)
        analytics.addFinished()
        analytics.addStarted(AnalyticsEvent.AddSource.FAB)
        analytics.addFinished()
        // An add outside an open sheet (none today) must not leak into the next count.
        analytics.entryAdded("b", "gym", MetricType.STRENGTH, fromPreset = false)
        analytics.addStarted(AnalyticsEvent.AddSource.FAB)
        analytics.addFinished()

        assertEquals(1, spy.events.count { it is AnalyticsEvent.ExerciseAddCompleted })
    }
}
