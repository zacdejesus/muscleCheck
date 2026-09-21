package com.zadkiel.musclecheck.analytics

import com.zadkiel.musclecheck.domain.model.MetricType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

/**
 * The event → name + parameters mapping. GA4 drops what breaks its rules without an error
 * (the event simply never shows up), so the rules are pinned here. Same cases as the iOS
 * `AnalyticsEventTests`: both platforms feed the same Firebase project.
 */
class AnalyticsEventTest {

    private val allEvents = listOf(
        AnalyticsEvent.OnboardingStarted,
        AnalyticsEvent.OnboardingCompleted(seedCount = 2, skipped = false),
        AnalyticsEvent.ActivityChecked("gym", MetricType.STRENGTH, secondsSinceOpen = 3),
        AnalyticsEvent.ExerciseAddStarted(AnalyticsEvent.AddSource.FAB),
        AnalyticsEvent.ExerciseAddCompleted("yoga", MetricType.DURATION, fromPreset = true, count = 2),
    )

    private val ga4Name = Regex("^[a-z][a-z0-9_]*$")

    @Test
    fun `names and parameters respect GA4 rules`() {
        for (event in allEvents) {
            assertTrue(event.name, event.name.length <= 40 && ga4Name.matches(event.name))
            // 25 per event including Firebase's automatic ones.
            assertTrue(event.parameters.size <= 20)
            for ((key, value) in event.parameters) {
                assertTrue(key, key.length <= 40 && ga4Name.matches(key))
                assertTrue(key, value is String || value is Long)
            }
        }
    }

    @Test
    fun `names match the plan and iOS`() {
        assertEquals(
            listOf(
                "onboarding_started",
                "onboarding_completed",
                "activity_checked",
                "exercise_add_started",
                "exercise_add_completed",
            ),
            allEvents.map { it.name },
        )
        assertEquals("empty_state", AnalyticsEvent.ExerciseAddStarted(AnalyticsEvent.AddSource.EMPTY_STATE).parameters["source"])
    }

    @Test
    fun `custom category ids never leave the device`() {
        val event = AnalyticsEvent.ActivityChecked(UUID.randomUUID().toString(), MetricType.NONE, null)

        assertEquals("custom", event.parameters["category"])
        assertEquals("running", AnalyticsEvent.categoryParameter("running"))
    }

    @Test
    fun `activity checked leaves unknown time out`() {
        val event = AnalyticsEvent.ActivityChecked("gym", MetricType.DISTANCE_DURATION, secondsSinceOpen = null)

        assertEquals("distanceDuration", event.parameters["metric"])
        assertEquals("app", event.parameters["source"])
        // Absent, not 0: a 0 would drag down the median that measures "2 seconds".
        assertFalse(event.parameters.containsKey("seconds_since_open"))
    }

    @Test
    fun `booleans travel as integers`() {
        val completed = AnalyticsEvent.OnboardingCompleted(seedCount = 3, skipped = true).parameters
        assertEquals(1L, completed["skipped"])
        assertEquals(3L, completed["seed_count"])

        val added = AnalyticsEvent.ExerciseAddCompleted("gym", MetricType.STRENGTH, fromPreset = false, count = 2).parameters
        assertEquals(0L, added["from_preset"])
        assertEquals(2L, added["count"])
    }
}
