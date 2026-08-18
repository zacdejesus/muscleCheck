package com.zadkiel.musclecheck.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.AppWeek
import com.zadkiel.musclecheck.domain.StreakCalculator
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.SessionInput
import com.zadkiel.musclecheck.domain.model.WeightUnit
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

data class CategoryGroup(val category: String, val entries: List<MuscleEntry>)

data class HomeUiState(
    val groups: List<CategoryGroup> = emptyList(),
    val allEntries: List<MuscleEntry> = emptyList(),
    val customCategories: List<CustomCategory> = emptyList(),
    val weightUnit: WeightUnit = WeightUnit.KG,
    val currentStreak: Int = 0,
    val maxStreak: Int = 0,
    val loaded: Boolean = false,
) {
    val isEmpty: Boolean get() = groups.isEmpty()
    val isStreakAlive: Boolean get() = currentStreak > 0
}

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: MuscleRepository,
    private val prefs: UserPreferencesRepository,
) : ViewModel() {

    /** Error shown inside the add sheet (duplicate/empty name). */
    val addError = MutableStateFlow<String?>(null)

    /** Category the add sheet opens on — the last one used. */
    val lastAddCategory = MutableStateFlow(ActivityCategory.GYM.id)

    init {
        viewModelScope.launch {
            repository.resetChecksIfNewWeek()
            // Resolve + persist the metric of entries created before metrics existed.
            repository.backfillMetricTypes()
        }
    }

    val uiState: StateFlow<HomeUiState> = combine(
        repository.entries,
        repository.customCategories,
        prefs.weightUnit,
    ) { entries, custom, unit ->
        val today = LocalDate.now()
        val currentWeek = AppWeek.weekOfYear(today)
        val currentYear = AppWeek.weekBasedYear(today)
        val currentWeekEntries = entries.filter { it.weekOfYear == currentWeek && it.year == currentYear }

        val groups = currentWeekEntries
            .groupBy { it.category }
            .toList()
            .sortedWith(compareBy({ CategoryResolver.sortKey(it.first).first }, { it.first }))
            .map { (category, list) -> CategoryGroup(category, list) }

        HomeUiState(
            groups = groups,
            allEntries = currentWeekEntries,
            customCategories = custom,
            weightUnit = unit,
            currentStreak = StreakCalculator.currentStreak(entries),
            maxStreak = StreakCalculator.maxStreak(entries),
            loaded = true,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HomeUiState())

    fun toggleActivity(entry: MuscleEntry) {
        viewModelScope.launch { repository.toggleActivity(entry) }
    }

    /** Group-level session (groups with no exercises yet). */
    fun saveSession(entry: MuscleEntry, input: SessionInput) {
        viewModelScope.launch { repository.saveTodaySession(entry.id, input) }
    }

    fun deleteEntry(entry: MuscleEntry) {
        viewModelScope.launch { repository.deleteEntry(entry.id) }
    }

    // MARK: - Exercises

    fun addExercise(entry: MuscleEntry, name: String, metric: MetricType, icon: String) {
        viewModelScope.launch {
            try {
                repository.addExercise(entry.id, name, metric, icon)
                addError.value = null
            } catch (e: Exception) {
                addError.value = repository.errorMessage(e)
            }
        }
    }

    fun deleteExercise(exercise: Exercise) {
        viewModelScope.launch { repository.deleteExercise(exercise.id) }
    }

    /** Saves an exercise's values; the repository also marks the group trained today. */
    fun logExercise(entry: MuscleEntry, exercise: Exercise, input: SessionInput) {
        viewModelScope.launch { repository.logExercise(entry.id, exercise.id, input) }
    }

    // MARK: - Add flow

    fun rememberAddCategory(categoryId: String) {
        lastAddCategory.value = categoryId
    }

    fun addPresetEntry(category: ActivityCategory, nameRes: Int, icon: String) {
        viewModelScope.launch { repository.addPresetEntry(category, nameRes, icon) }
    }

    fun addEntry(name: String, category: String, icon: String, metric: MetricType) {
        viewModelScope.launch {
            try {
                repository.addEntry(name, category, icon, metric)
                addError.value = null
            } catch (e: Exception) {
                addError.value = repository.errorMessage(e)
            }
        }
    }

    fun createCategory(name: String, icon: String, metric: MetricType) {
        viewModelScope.launch {
            try {
                repository.addCustomCategory(name, icon, metric)
                addError.value = null
            } catch (e: Exception) {
                addError.value = repository.errorMessage(e)
            }
        }
    }

    fun clearAddError() {
        addError.value = null
    }
}
