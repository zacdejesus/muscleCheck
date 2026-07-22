package com.zadkiel.musclecheck.data.local

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation
import com.zadkiel.musclecheck.domain.model.CustomCategory
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
)

@Entity(tableName = "custom_categories")
data class CustomCategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String,
    val sortOrder: Int,
    val tracksWeight: Boolean,
)

/** Progress photo metadata; the image itself lives on disk (internal storage),
 *  not in the DB — same as iOS (ProgressPhoto). */
@Entity(tableName = "progress_photos")
data class ProgressPhotoEntity(
    @PrimaryKey val id: String,
    val epochDay: Long,
    val fileName: String,
)

data class EntryWithSessions(
    @Embedded val entry: MuscleEntryEntity,
    @Relation(parentColumn = "id", entityColumn = "entryId")
    val sessions: List<WorkoutSessionEntity>,
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
)

fun WorkoutSessionEntity.toDomain(): WorkoutSession = WorkoutSession(
    id = id,
    date = LocalDate.ofEpochDay(epochDay),
    weightKg = weightKg,
    sets = sets,
    reps = reps,
)

fun CustomCategoryEntity.toDomain(): CustomCategory = CustomCategory(
    id = id,
    name = name,
    icon = icon,
    sortOrder = sortOrder,
    tracksWeight = tracksWeight,
)

fun ProgressPhotoEntity.toDomain(): ProgressPhoto = ProgressPhoto(
    id = id,
    date = LocalDate.ofEpochDay(epochDay),
    fileName = fileName,
)
