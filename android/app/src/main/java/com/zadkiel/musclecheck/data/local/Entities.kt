package com.zadkiel.musclecheck.data.local

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.ProgressPhoto
import com.zadkiel.musclecheck.domain.model.WorkoutSession
import java.time.Instant
import java.time.LocalDate

@Entity(tableName = "muscle_entries")
data class MuscleEntryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val isChecked: Boolean,
    val weekOfYear: Int,
    val year: Int,
    /** Epoch millis. */
    val dateCreated: Long,
    val category: String,
    val icon: String,
    /** Raw MetricType id; "" = pre-metric entry, resolved from the category at read time. */
    val metricRaw: String = "",
)

@Entity(
    tableName = "workout_sessions",
    foreignKeys = [
        ForeignKey(
            entity = MuscleEntryEntity::class,
            parentColumns = ["id"],
            childColumns = ["entryId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("entryId")],
)
data class WorkoutSessionEntity(
    @PrimaryKey val id: String,
    val entryId: String,
    /** LocalDate.toEpochDay — sessions are day-granular, like iOS same-day semantics. */
    val epochDay: Long,
    val weightKg: Double?,
    val sets: Int?,
    val reps: Int?,
    /** Session length in seconds (duration / distanceDuration metrics). */
    val durationSeconds: Int? = null,
    /** Distance in meters (distanceDuration metric). */
    val distanceMeters: Double? = null,
)

/**
 * An exercise inside a group. Relational rather than the inline Codable array iOS
 * uses — same reason `workout_sessions` is its own table: Room is relational and a
 * blob column would give up querying for nothing.
 */
@Entity(
    tableName = "exercises",
    foreignKeys = [
        ForeignKey(
            entity = MuscleEntryEntity::class,
            parentColumns = ["id"],
            childColumns = ["entryId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("entryId")],
)
data class ExerciseEntity(
    @PrimaryKey val id: String,
    val entryId: String,
    val name: String,
    val icon: String,
    val metricRaw: String,
    val sortOrder: Int,
)

/** Per-exercise value history. Separate from `workout_sessions`, which stays the
 *  group-level "trained that day" record read by streak/stats/widget. */
@Entity(
    tableName = "exercise_sessions",
    foreignKeys = [
        ForeignKey(
            entity = ExerciseEntity::class,
            parentColumns = ["id"],
            childColumns = ["exerciseId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("exerciseId")],
)
data class ExerciseSessionEntity(
    @PrimaryKey val id: String,
    val exerciseId: String,
    val epochDay: Long,
    val weightKg: Double?,
    val sets: Int?,
    val reps: Int?,
    val durationSeconds: Int?,
    val distanceMeters: Double?,
)

@Entity(tableName = "custom_categories")
data class CustomCategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String,
    val sortOrder: Int,
    /** Legacy Feature-17 flag; migration source for [defaultMetricRaw]. */
    val tracksWeight: Boolean,
    val defaultMetricRaw: String = "",
)

/** Progress photo metadata; the image itself lives on disk (internal storage),
 *  not in the DB — same as iOS (ProgressPhoto). */
@Entity(tableName = "progress_photos")
data class ProgressPhotoEntity(
    @PrimaryKey val id: String,
    val epochDay: Long,
    val fileName: String,
)

data class ExerciseWithSessions(
    @Embedded val exercise: ExerciseEntity,
    @Relation(parentColumn = "id", entityColumn = "exerciseId")
    val sessions: List<ExerciseSessionEntity>,
)

data class EntryWithSessions(
    @Embedded val entry: MuscleEntryEntity,
    @Relation(parentColumn = "id", entityColumn = "entryId")
    val sessions: List<WorkoutSessionEntity>,
    @Relation(parentColumn = "id", entityColumn = "entryId", entity = ExerciseEntity::class)
    val exercises: List<ExerciseWithSessions>,
)

// MARK: - Mapping to domain

fun EntryWithSessions.toDomain(): MuscleEntry = MuscleEntry(
    id = entry.id,
    name = entry.name,
    isChecked = entry.isChecked,
    weekOfYear = entry.weekOfYear,
    year = entry.year,
    dateCreated = Instant.ofEpochMilli(entry.dateCreated),
    category = entry.category,
    icon = entry.icon,
    sessions = sessions.map { it.toDomain() }.sortedBy { it.date },
    metricRaw = entry.metricRaw,
    exercises = exercises.sortedBy { it.exercise.sortOrder }.map { it.toDomain() },
)

fun ExerciseWithSessions.toDomain(): Exercise = Exercise(
    id = exercise.id,
    name = exercise.name,
    icon = exercise.icon,
    metricRaw = exercise.metricRaw,
    sessions = sessions.map { it.toDomain() }.sortedBy { it.date },
)

fun WorkoutSessionEntity.toDomain(): WorkoutSession = WorkoutSession(
    id = id,
    date = LocalDate.ofEpochDay(epochDay),
    weightKg = weightKg,
    sets = sets,
    reps = reps,
    durationSeconds = durationSeconds,
    distanceMeters = distanceMeters,
)

fun ExerciseSessionEntity.toDomain(): WorkoutSession = WorkoutSession(
    id = id,
    date = LocalDate.ofEpochDay(epochDay),
    weightKg = weightKg,
    sets = sets,
    reps = reps,
    durationSeconds = durationSeconds,
    distanceMeters = distanceMeters,
)

fun CustomCategoryEntity.toDomain(): CustomCategory = CustomCategory(
    id = id,
    name = name,
    icon = icon,
    sortOrder = sortOrder,
    tracksWeight = tracksWeight,
    defaultMetricRaw = defaultMetricRaw,
)

fun ProgressPhotoEntity.toDomain(): ProgressPhoto = ProgressPhoto(
    id = id,
    date = LocalDate.ofEpochDay(epochDay),
    fileName = fileName,
)
