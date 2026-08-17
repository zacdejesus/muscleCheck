package com.zadkiel.musclecheck.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        MuscleEntryEntity::class,
        WorkoutSessionEntity::class,
        ExerciseEntity::class,
        ExerciseSessionEntity::class,
        CustomCategoryEntity::class,
        ProgressPhotoEntity::class,
    ],
    // v3: per-exercise metrics + exercises inside a group.
    version = 3,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun muscleDao(): MuscleDao
    abstract fun categoryDao(): CategoryDao
    abstract fun progressPhotoDao(): ProgressPhotoDao
}
