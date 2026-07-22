package com.zadkiel.musclecheck.data.repository

import android.content.Context
import com.zadkiel.musclecheck.data.local.CategoryDao
import com.zadkiel.musclecheck.data.local.CustomCategoryEntity
import com.zadkiel.musclecheck.data.local.MuscleDao
import com.zadkiel.musclecheck.data.local.MuscleEntryEntity
import com.zadkiel.musclecheck.data.local.WorkoutSessionEntity
import com.zadkiel.musclecheck.data.local.toDomain
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.domain.AppWeek
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.widget.MuscleCheckWidget
import androidx.glance.appwidget.updateAll
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

class DuplicateEntryException(val entryName: String) : Exception()
class InvalidNameException : Exception()

/** Port of MuscleEntryManager + CategoryStore over Room, exposing Flows. */
@Singleton
class MuscleRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val muscleDao: MuscleDao,
    private val categoryDao: CategoryDao,
    private val prefs: UserPreferencesRepository,
) {

    val entries: Flow<List<MuscleEntry>> =
        muscleDao.observeEntriesWithSessions().map { list -> list.map { it.toDomain() } }

    val customCategories: Flow<List<CustomCategory>> =
        categoryDao.observeAll().map { list -> list.map { it.toDomain() } }

    // MARK: - Entries

    /** Adds a new entry, trimming the name and rejecting duplicates. */
    suspend fun addEntry(name: String, category: String, icon: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) throw InvalidNameException()
        if (muscleDao.countByName(trimmed) > 0) throw DuplicateEntryException(trimmed)
        muscleDao.insertEntry(newEntryEntity(trimmed, category, icon))
        refreshWidget()
    }

    /** Adds all preset entries for a category, skipping duplicates, and marks the preset added. */
    suspend fun addPresetEntries(category: ActivityCategory) {
        for (preset in category.presetEntries) {
            val name = context.getString(preset.nameRes).trim()
            if (name.isEmpty() || muscleDao.countByName(name) > 0) continue
            muscleDao.insertEntry(newEntryEntity(name, category.id, preset.icon))
        }
        prefs.markPresetAdded(category.id)
        refreshWidget()
    }

    suspend fun deleteEntry(id: String) {
        muscleDao.deleteEntry(id)
        refreshWidget()
    }

    /**
     * Toggles today's activity: unchecking removes today's session, checking logs one
     * (carrying over the last recorded weight, matching iOS `addSession`).
     */
    suspend fun toggleActivity(entry: MuscleEntry, today: LocalDate = LocalDate.now()) {
        if (entry.isChecked) {
            muscleDao.deleteSessionsOn(entry.id, today.toEpochDay())
            muscleDao.setChecked(entry.id, false)
        } else {
            if (muscleDao.sessionOn(entry.id, today.toEpochDay()) == null) {
                val carriedWeight = entry.lastWeightKg
                muscleDao.insertSession(
                    WorkoutSessionEntity(
                        id = UUID.randomUUID().toString(),
                        entryId = entry.id,
                        epochDay = today.toEpochDay(),
                        weightKg = carriedWeight,
                        sets = null,
                        reps = null,
                    )
                )
            }
            muscleDao.setChecked(entry.id, true)
        }
        refreshWidget()
    }

    /**
     * Sets (or updates) today's session: weight (kg), sets and reps. Premise: "if I log
     * something today, I trained today" — so this also checks the entry.
     */
    suspend fun saveTodaySession(
        entryId: String,
        weightKg: Double?,
        sets: Int?,
        reps: Int?,
        today: LocalDate = LocalDate.now(),
    ) {
        val existing = muscleDao.sessionOn(entryId, today.toEpochDay())
        muscleDao.insertSession(
            WorkoutSessionEntity(
                id = existing?.id ?: UUID.randomUUID().toString(),
                entryId = entryId,
                epochDay = today.toEpochDay(),
                weightKg = weightKg,
                sets = sets,
                reps = reps,
            )
        )
        muscleDao.setChecked(entryId, true)
        refreshWidget()
    }

    /** Clears all checks and moves entries to the current week when the week changed. */
    suspend fun resetChecksIfNewWeek(today: LocalDate = LocalDate.now()) {
        val currentWeek = AppWeek.weekOfYear(today)
        val currentYear = AppWeek.weekBasedYear(today)
        if (currentWeek != prefs.lastResetWeek() || currentYear != prefs.lastResetYear()) {
            muscleDao.resetAllForNewWeek(currentWeek, currentYear)
            prefs.setLastReset(currentWeek, currentYear)
            refreshWidget()
        }
    }

    // MARK: - Custom categories

    suspend fun addCustomCategory(name: String, icon: String, tracksWeight: Boolean) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) throw InvalidNameException()
        val existing = categoryDao.getAll()
        if (existing.any { it.name.equals(trimmed, ignoreCase = true) }) {
            throw DuplicateEntryException(trimmed)
        }
        val nextOrder = (existing.maxOfOrNull { it.sortOrder } ?: (ActivityCategory.entries.size - 1)) + 1
        categoryDao.insert(
            CustomCategoryEntity(
                id = UUID.randomUUID().toString(),
                name = trimmed,
                icon = icon,
                sortOrder = nextOrder,
                tracksWeight = tracksWeight,
            )
        )
    }

    /** Entries referencing the deleted category become orphans; CategoryResolver degrades them. */
    suspend fun deleteCustomCategory(id: String) {
        categoryDao.delete(id)
    }

    // MARK: - Onboarding seed

    /** Seeds the preset entries for the categories picked in onboarding and completes it. */
    suspend fun completeOnboarding(selected: List<ActivityCategory>) {
        for (category in selected) {
            addPresetEntries(category)
        }
        if (selected.isNotEmpty()) prefs.setDefaultEntriesCreated(true)
        prefs.setHasCompletedOnboarding(true)
    }

    /** Mirrors the iOS WidgetCenter.reloadTimelines call after every data mutation. */
    private suspend fun refreshWidget() {
        MuscleCheckWidget().updateAll(context)
    }

    private fun newEntryEntity(name: String, category: String, icon: String): MuscleEntryEntity {
        val today = LocalDate.now()
        return MuscleEntryEntity(
            id = UUID.randomUUID().toString(),
            name = name,
            isChecked = false,
            weekOfYear = AppWeek.weekOfYear(today),
            year = AppWeek.weekBasedYear(today),
            dateCreated = Instant.now().toEpochMilli(),
            category = category,
            icon = icon,
        )
    }

    /** Localized error message matching the iOS copy. */
    fun errorMessage(e: Exception): String = when (e) {
        is DuplicateEntryException -> context.getString(R.string.error_duplicate_entry, e.entryName)
        is InvalidNameException -> context.getString(R.string.error_invalid_name)
        else -> e.message ?: e.javaClass.simpleName
    }
}
