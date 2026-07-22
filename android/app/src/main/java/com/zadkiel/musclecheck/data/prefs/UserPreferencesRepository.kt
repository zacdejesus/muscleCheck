package com.zadkiel.musclecheck.data.prefs

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.WeightUnit
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalTime
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "musclecheck_prefs")

/** DataStore port of the iOS UserDefaultsManager. */
@Singleton
class UserPreferencesRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private object Keys {
        val lastResetWeek = intPreferencesKey("lastResetWeek")
        val lastResetYear = intPreferencesKey("lastResetYear")
        val defaultEntriesCreated = booleanPreferencesKey("defaultEntriesCreated")
        val hasCompletedOnboarding = booleanPreferencesKey("hasCompletedOnboarding")
        val appTheme = intPreferencesKey("appTheme") // 0 = system, 1 = light, 2 = dark
        val weightUnit = stringPreferencesKey("weightUnit")
        val addedActivityPresets = stringSetPreferencesKey("addedActivityPresets")
        val notificationsEnabled = booleanPreferencesKey("notificationsEnabled")
        val reminderHour = intPreferencesKey("reminderHour")
        val reminderMinute = intPreferencesKey("reminderMinute")
    }

    val hasCompletedOnboarding: Flow<Boolean> =
        context.dataStore.data.map { it[Keys.hasCompletedOnboarding] ?: false }

    val appTheme: Flow<Int> =
        context.dataStore.data.map { it[Keys.appTheme] ?: 0 }

    val weightUnit: Flow<WeightUnit> =
        context.dataStore.data.map { WeightUnit.fromId(it[Keys.weightUnit]) }

    val addedActivityPresets: Flow<Set<String>> =
        context.dataStore.data.map { it[Keys.addedActivityPresets] ?: setOf(ActivityCategory.GYM.id) }

    val notificationsEnabled: Flow<Boolean> =
        context.dataStore.data.map { it[Keys.notificationsEnabled] ?: false }

    /** Daily reminder time; defaults to 18:00 like iOS. */
    val reminderTime: Flow<LocalTime> =
        context.dataStore.data.map {
            LocalTime.of(it[Keys.reminderHour] ?: 18, it[Keys.reminderMinute] ?: 0)
        }

    suspend fun setHasCompletedOnboarding(value: Boolean) {
        context.dataStore.edit { it[Keys.hasCompletedOnboarding] = value }
    }

    suspend fun setDefaultEntriesCreated(value: Boolean) {
        context.dataStore.edit { it[Keys.defaultEntriesCreated] = value }
    }

    suspend fun defaultEntriesCreated(): Boolean =
        context.dataStore.data.map { it[Keys.defaultEntriesCreated] ?: false }.first()

    suspend fun setAppTheme(value: Int) {
        context.dataStore.edit { it[Keys.appTheme] = value }
    }

    suspend fun setWeightUnit(unit: WeightUnit) {
        context.dataStore.edit { it[Keys.weightUnit] = unit.id }
    }

    suspend fun setNotificationsEnabled(value: Boolean) {
        context.dataStore.edit { it[Keys.notificationsEnabled] = value }
    }

    suspend fun setReminderTime(hour: Int, minute: Int) {
        context.dataStore.edit {
            it[Keys.reminderHour] = hour
            it[Keys.reminderMinute] = minute
        }
    }

    suspend fun markPresetAdded(categoryId: String) {
        context.dataStore.edit { prefs ->
            val current = prefs[Keys.addedActivityPresets] ?: setOf(ActivityCategory.GYM.id)
            prefs[Keys.addedActivityPresets] = current + categoryId
        }
    }

    suspend fun lastResetWeek(): Int =
        context.dataStore.data.map { it[Keys.lastResetWeek] ?: 0 }.first()

    suspend fun lastResetYear(): Int =
        context.dataStore.data.map { it[Keys.lastResetYear] ?: 0 }.first()

    suspend fun setLastReset(week: Int, year: Int) {
        context.dataStore.edit {
            it[Keys.lastResetWeek] = week
            it[Keys.lastResetYear] = year
        }
    }
}
