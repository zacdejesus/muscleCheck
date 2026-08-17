package com.zadkiel.musclecheck.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface MuscleDao {

    @Transaction
    @Query("SELECT * FROM muscle_entries ORDER BY dateCreated")
    fun observeEntriesWithSessions(): Flow<List<EntryWithSessions>>

    @Transaction
    @Query("SELECT * FROM muscle_entries ORDER BY dateCreated")
    suspend fun getEntriesWithSessions(): List<EntryWithSessions>

    /** Case-insensitive, matching the unified duplicate rule of iOS `normalizedName`. */
    @Query("SELECT COUNT(*) FROM muscle_entries WHERE name = :name COLLATE NOCASE")
    suspend fun countByName(name: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: MuscleEntryEntity)

    @Query("DELETE FROM muscle_entries WHERE id = :id")
    suspend fun deleteEntry(id: String)

    @Query("UPDATE muscle_entries SET isChecked = :checked WHERE id = :id")
    suspend fun setChecked(id: String, checked: Boolean)

    @Query("UPDATE muscle_entries SET isChecked = 0, weekOfYear = :week, year = :year")
    suspend fun resetAllForNewWeek(week: Int, year: Int)

    // MARK: - Sessions

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: WorkoutSessionEntity)

    @Query("SELECT * FROM workout_sessions WHERE entryId = :entryId AND epochDay = :epochDay LIMIT 1")
    suspend fun sessionOn(entryId: String, epochDay: Long): WorkoutSessionEntity?

    @Query("DELETE FROM workout_sessions WHERE entryId = :entryId AND epochDay = :epochDay")
    suspend fun deleteSessionsOn(entryId: String, epochDay: Long)

    @Query("SELECT * FROM workout_sessions WHERE entryId = :entryId ORDER BY epochDay DESC")
    suspend fun sessionsFor(entryId: String): List<WorkoutSessionEntity>

    @Query("UPDATE muscle_entries SET metricRaw = :metricRaw WHERE id = :id")
    suspend fun setMetric(id: String, metricRaw: String)

    /** Entries created before per-exercise metrics existed (backfilled at startup). */
    @Query("SELECT * FROM muscle_entries WHERE metricRaw = ''")
    suspend fun entriesWithoutMetric(): List<MuscleEntryEntity>

    // MARK: - Exercises

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExercise(exercise: ExerciseEntity)

    @Query("DELETE FROM exercises WHERE id = :id")
    suspend fun deleteExercise(id: String)

    @Query("SELECT COALESCE(MAX(sortOrder), -1) FROM exercises WHERE entryId = :entryId")
    suspend fun maxExerciseOrder(entryId: String): Int

    @Query("SELECT COUNT(*) FROM exercises WHERE entryId = :entryId AND name = :name COLLATE NOCASE")
    suspend fun countExerciseByName(entryId: String, name: String): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExerciseSession(session: ExerciseSessionEntity)

    @Query("SELECT * FROM exercise_sessions WHERE exerciseId = :exerciseId AND epochDay = :epochDay LIMIT 1")
    suspend fun exerciseSessionOn(exerciseId: String, epochDay: Long): ExerciseSessionEntity?
}

@Dao
interface CategoryDao {

    @Query("SELECT * FROM custom_categories ORDER BY sortOrder")
    fun observeAll(): Flow<List<CustomCategoryEntity>>

    @Query("SELECT * FROM custom_categories ORDER BY sortOrder")
    suspend fun getAll(): List<CustomCategoryEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(category: CustomCategoryEntity)

    @Query("DELETE FROM custom_categories WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface ProgressPhotoDao {

    @Query("SELECT * FROM progress_photos ORDER BY epochDay DESC, id DESC")
    fun observeAll(): Flow<List<ProgressPhotoEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(photo: ProgressPhotoEntity)

    @Query("DELETE FROM progress_photos WHERE id = :id")
    suspend fun delete(id: String)
}
