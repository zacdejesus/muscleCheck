package com.zadkiel.musclecheck.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.MonthCalendarCalculator
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WeightUnit
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale
import javax.inject.Inject

data class HistoryUiState(
    val entries: List<MuscleEntry> = emptyList(),
    val customCategories: List<CustomCategory> = emptyList(),
    val weightUnit: WeightUnit = WeightUnit.KG,
    val selectedDate: LocalDate = LocalDate.now(),
    val displayedMonth: LocalDate = LocalDate.now(),
    val isCalendarExpanded: Boolean = false,
) {
    val weeks get() = MonthCalendarCalculator.monthMatrix(displayedMonth)
    val selectedWeek get() = MonthCalendarCalculator.weekRow(selectedDate)
    val intensityByDay get() = MonthCalendarCalculator.muscleCountByDay(entries)
    val monthTrainedCount get() = MonthCalendarCalculator.trainedDayCount(displayedMonth, entries)
    val weekBreakdown get() = MonthCalendarCalculator.weekBreakdown(selectedDate, entries)

    /** "Junio 2026" — capitalized for the header. */
    val monthTitle: String
        get() = DateTimeFormatter.ofPattern("LLLL yyyy", Locale.getDefault())
            .format(displayedMonth)
            .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }

    /** "junio" — lowercase, used mid-sentence in the month summary caption. */
    val monthName: String
        get() = DateTimeFormatter.ofPattern("LLLL", Locale.getDefault()).format(displayedMonth)
}

@HiltViewModel
class HistoryViewModel @Inject constructor(
    repository: MuscleRepository,
    prefs: UserPreferencesRepository,
) : ViewModel() {

    private val selection = MutableStateFlow(
        Triple(LocalDate.now(), LocalDate.now(), false) // selectedDate, displayedMonth, isExpanded
    )

    val uiState: StateFlow<HistoryUiState> = combine(
        repository.entries,
        repository.customCategories,
        prefs.weightUnit,
        selection,
    ) { entries, custom, unit, (selected, month, expanded) ->
        HistoryUiState(
            entries = entries,
            customCategories = custom,
            weightUnit = unit,
            selectedDate = selected,
            displayedMonth = month,
            isCalendarExpanded = expanded,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HistoryUiState())

    fun select(day: LocalDate) {
        val (_, month, _) = selection.value
        // Tapping a leading/trailing day follows it into its month; picking a day
        // collapses back to its week (Calendar.app behavior).
        val newMonth = if (YearMonth.from(day) != YearMonth.from(month)) day else month
        selection.value = Triple(day, newMonth, false)
    }

    fun goToPreviousMonth() = shiftMonth(-1)
    fun goToNextMonth() = shiftMonth(1)

    private fun shiftMonth(value: Long) {
        val (selected, month, expanded) = selection.value
        selection.value = Triple(selected, month.plusMonths(value), expanded)
    }

    fun goToPreviousWeek() = shiftSelectedWeek(-1)
    fun goToNextWeek() = shiftSelectedWeek(1)

    /** Moves the collapsed view a week at a time, keeping the header label in step. */
    private fun shiftSelectedWeek(value: Long) {
        val (selected, _, expanded) = selection.value
        val next = selected.plusWeeks(value)
        selection.value = Triple(next, next, expanded)
    }

    fun toggleCalendarExpanded() {
        val (selected, month, expanded) = selection.value
        // Expanding shows the month around the selected day.
        selection.value = Triple(selected, if (!expanded) selected else month, !expanded)
    }
}
