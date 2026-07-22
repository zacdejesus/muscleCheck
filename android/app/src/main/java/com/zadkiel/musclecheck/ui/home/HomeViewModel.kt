package com.zadkiel.musclecheck.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.AppWeek
import com.zadkiel.musclecheck.domain.StreakCalculator
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MuscleEntry
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
    prefs: UserPreferencesRepository,
) : ViewModel() {

    /** Error shown inside the add sheet (duplicate/empty name). */
    val addError = MutableStateFlow<String?>(null)

    init {
        viewModelScope.launch { repository.resetChecksIfNewWeek() }
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

    fun saveSession(entry: MuscleEntry, weightKg: Double?, sets: Int?, reps: Int?) {
        viewModelScope.launch { repository.saveTodaySession(entry.id, weightKg, sets, reps) }
    }

    fun deleteEntry(entry: MuscleEntry) {
        viewModelScope.launch { repository.deleteEntry(entry.id) }
    }

    /** Returns via callback so the sheet can close only on success. */
    fun addEntry(name: String, category: String, icon: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            try {
                repository.addEntry(name, category, icon)
                addError.value = null
                onSuccess()
            } catch (e: Exception) {
                addError.value = repository.errorMessage(e)
            }
        }
    }

    fun clearAddError() {
        addError.value = null
    }
}
