package com.zadkiel.musclecheck.di

import android.content.Context
import androidx.room.Room
import com.zadkiel.musclecheck.data.local.AppDatabase
import com.zadkiel.musclecheck.data.local.CategoryDao
import com.zadkiel.musclecheck.data.local.MuscleDao
import com.zadkiel.musclecheck.data.local.ProgressPhotoDao
import com.zadkiel.musclecheck.data.pro.LocalProAccessManager
import com.zadkiel.musclecheck.data.pro.ProAccessManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, "musclecheck.db")
            // v2 adds progress_photos; no released users, so a destructive migration
            // is fine (mirrors the iOS wipe-on-schema-change fallback).
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun provideMuscleDao(db: AppDatabase): MuscleDao = db.muscleDao()

    @Provides
    fun provideCategoryDao(db: AppDatabase): CategoryDao = db.categoryDao()

    @Provides
    fun provideProgressPhotoDao(db: AppDatabase): ProgressPhotoDao = db.progressPhotoDao()

    // Swap LocalProAccessManager for a RevenueCat-backed impl once billing is set up.
    @Provides
    @Singleton
    fun provideProAccessManager(impl: LocalProAccessManager): ProAccessManager = impl
}
