package com.zadkiel.musclecheck.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        MuscleEntryEntity::class,
        WorkoutSessionEntity::class,
        CustomCategoryEntity::class,
        ProgressPhotoEntity::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun muscleDao(): MuscleDao
    abstract fun categoryDao(): CategoryDao
    abstract fun progressPhotoDao(): ProgressPhotoDao
}
