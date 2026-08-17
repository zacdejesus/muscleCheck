package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.SessionFormatting
import com.zadkiel.musclecheck.domain.model.WeightUnit
import com.zadkiel.musclecheck.domain.model.WorkoutSession
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant
import java.time.LocalDate

/** Ported from the iOS `ExerciseTests` / `MuscleEntryExerciseTests` semantics. */
class MetricAndExerciseTest {

    private val today = LocalDate.of(2026, 8, 12)

    private fun session(
        day: LocalDate,
        weightKg: Double? = null,
        durationSeconds: Int? = null,
        distanceMeters: Double? = null,
    ) = WorkoutSession(
        id = "s-$day-$weightKg-$durationSeconds-$distanceMeters",
        date = day,
        weightKg = weightKg,
        durationSeconds = durationSeconds,
        distanceMeters = distanceMeters,
    )

    private fun entry(
        category: String = ActivityCategory.GYM.id,
        metricRaw: String = "",
        sessions: List<WorkoutSession> = emptyList(),
        exercises: List<Exercise> = emptyList(),
    ) = MuscleEntry(
        id = "e1",
        name = "Legs",
        isChecked = false,
        weekOfYear = 33,
        year = 2026,
        dateCreated = Instant.EPOCH,
        category = category,
        icon = "figure.strengthtraining.traditional",
        sessions = sessions,
        metricRaw = metricRaw,
        exercises = exercises,
    )

    // MARK: - Metric resolution

    @Test
    fun `empty metric falls back to the built-in category default`() {
        assertEquals(MetricType.STRENGTH, entry(category = "gym").metric)
        assertEquals(MetricType.DISTANCE_DURATION, entry(category = "running").metric)
        assertEquals(MetricType.DURATION, entry(category = "yoga").metric)
        assertEquals(MetricType.NONE, entry(category = "stretching").metric)
    }

    @Test
    fun `explicit metric overrides the category default`() {
        assertEquals(MetricType.DURATION, entry(category = "gym", metricRaw = "duration").metric)
    }

    @Test
    fun `custom category default resolves through the resolver overload`() {
        val custom = CustomCategory(
            id = "cat-1", name = "Boxing", icon = "star.fill",
            sortOrder = 9, tracksWeight = false, defaultMetricRaw = "duration",
        )
        assertEquals(MetricType.DURATION, entry(category = "cat-1").metricResolving(listOf(custom)))
    }

    @Test
    fun `custom category without a metric migrates from tracksWeight`() {
        val legacy = CustomCategory("c", "Legacy", "star.fill", 9, tracksWeight = true)
        assertEquals(MetricType.STRENGTH, legacy.defaultMetric)
        val legacyNoWeight = legacy.copy(tracksWeight = false)
        assertEquals(MetricType.NONE, legacyNoWeight.defaultMetric)
    }

    // MARK: - Formatting

    @Test
    fun `label formats each metric and returns null when nothing is recorded`() {
        assertNull(SessionFormatting.label(MetricType.NONE, weightKg = 100.0))
        assertEquals("100 kg", SessionFormatting.label(MetricType.STRENGTH, weightKg = 100.0))
        assertEquals("45 min", SessionFormatting.label(MetricType.DURATION, durationSeconds = 2700))
        assertEquals(
            "5.2 km · 32 min",
            SessionFormatting.label(
                MetricType.DISTANCE_DURATION,
                durationSeconds = 1920,
                distanceMeters = 5200.0,
            ),
        )
        assertNull(SessionFormatting.label(MetricType.STRENGTH, weightKg = null))
    }

    @Test
    fun `distanceDuration keeps the single value it has`() {
        assertEquals(
            "5.0 km",
            SessionFormatting.label(MetricType.DISTANCE_DURATION, distanceMeters = 5000.0),
        )
    }

    @Test
    fun `weight is converted to the display unit`() {
        assertEquals("220 lbs", SessionFormatting.formatWeight(100.0, WeightUnit.LBS))
    }

    // MARK: - Exercise

    @Test
    fun `last values come from the most recent session that has them`() {
        val exercise = Exercise(
            id = "x", name = "Deadlift", icon = "i", metricRaw = "strength",
            sessions = listOf(
                session(today.minusDays(5), weightKg = 80.0),
                session(today.minusDays(1), weightKg = 100.0),
                session(today), // no values: must not erase the last known weight
            ),
        )
        assertEquals(100.0, exercise.lastWeightKg!!, 0.001)
        assertEquals("100 kg", exercise.summary(WeightUnit.KG))
    }

    @Test
    fun `distance and duration are read from the same session`() {
        val exercise = Exercise(
            id = "x", name = "Run", icon = "i", metricRaw = "distanceDuration",
            sessions = listOf(
                session(today.minusDays(3), distanceMeters = 10000.0),
                session(today, durationSeconds = 1800, distanceMeters = 5000.0),
            ),
        )
        // Not "10.0 km · 30 min": both values belong to today's session.
        assertEquals("5.0 km · 30 min", exercise.summary(WeightUnit.KG))
    }

    // MARK: - Group summary

    @Test
    fun `group with no exercises falls back to its own value`() {
        val group = entry(metricRaw = "strength", sessions = listOf(session(today, weightKg = 60.0)))
        val summary = group.summary(WeightUnit.KG)!!
        assertEquals(0, summary.exerciseCount)
        assertEquals("60 kg", summary.ownLabel)
    }

    @Test
    fun `group with exercises reports the count and the most recent one`() {
        val group = entry(
            metricRaw = "strength",
            exercises = listOf(
                Exercise("a", "Squat", "i", "strength", listOf(session(today.minusDays(2), weightKg = 90.0))),
                Exercise("b", "Deadlift", "i", "strength", listOf(session(today, weightKg = 120.0))),
            ),
        )
        val summary = group.summary(WeightUnit.KG)!!
        assertEquals(2, summary.exerciseCount)
        assertEquals("Deadlift", summary.recentName)
        assertEquals("120 kg", summary.recentValue)
    }

    @Test
    fun `group with exercises that were never logged reports only the count`() {
        val group = entry(
            metricRaw = "strength",
            exercises = listOf(Exercise("a", "Squat", "i", "strength", emptyList())),
        )
        val summary = group.summary(WeightUnit.KG)!!
        assertEquals(1, summary.exerciseCount)
        assertNull(summary.recentValue)
    }

    @Test
    fun `group with nothing logged has no summary`() {
        assertNull(entry(metricRaw = "strength").summary(WeightUnit.KG))
    }
}
