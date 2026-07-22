package com.zadkiel.musclecheck.ui.history

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.EventBusy
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.CalendarDay
import com.zadkiel.musclecheck.domain.DayActivities
import com.zadkiel.musclecheck.domain.MonthCalendarCalculator
import com.zadkiel.musclecheck.domain.AppWeek
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.WeightUnit
import com.zadkiel.musclecheck.ui.icons.AppIcons
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    onBack: () -> Unit,
    viewModel: HistoryViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.workout_history)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            // Month summary caption
            Text(
                text = stringResource(R.string.history_month_summary, state.monthTrainedCount, state.monthName),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp),
            )

            // Hero calendar
            MonthCalendar(
                weeks = state.weeks,
                selectedWeek = state.selectedWeek,
                monthTitle = state.monthTitle,
                intensityByDay = state.intensityByDay,
                selectedDate = state.selectedDate,
                isExpanded = state.isCalendarExpanded,
                onPrev = { if (state.isCalendarExpanded) viewModel.goToPreviousMonth() else viewModel.goToPreviousWeek() },
                onNext = { if (state.isCalendarExpanded) viewModel.goToNextMonth() else viewModel.goToNextWeek() },
                onToggleExpand = { viewModel.toggleCalendarExpanded() },
                onSelect = { viewModel.select(it) },
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
                    .padding(16.dp),
            )

            // Selected week, day by day
            WeekDetailSection(
                days = state.weekBreakdown,
                customCategories = state.customCategories,
                weightUnit = state.weightUnit,
            )
        }
    }
}

// MARK: - Month calendar

@Composable
private fun MonthCalendar(
    weeks: List<List<CalendarDay>>,
    selectedWeek: List<CalendarDay>,
    monthTitle: String,
    intensityByDay: Map<LocalDate, Int>,
    selectedDate: LocalDate,
    isExpanded: Boolean,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    onToggleExpand: () -> Unit,
    onSelect: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // Header (month/week pager + expand toggle)
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onPrev) {
                Icon(Icons.Filled.ChevronLeft, contentDescription = stringResource(R.string.previous), tint = MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.weight(1f))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier.clickable { onToggleExpand() },
            ) {
                Text(
                    text = monthTitle,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
                Icon(
                    imageVector = if (isExpanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                    contentDescription = stringResource(
                        if (isExpanded) R.string.history_calendar_collapse_hint else R.string.history_calendar_expand_hint
                    ),
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(18.dp),
                )
            }
            Spacer(Modifier.weight(1f))
            IconButton(onClick = onNext) {
                Icon(Icons.Filled.ChevronRight, contentDescription = stringResource(R.string.next), tint = MaterialTheme.colorScheme.primary)
            }
        }

        // Weekday symbols
        val symbols = remember { MonthCalendarCalculator.weekdaySymbols() }
        Row(modifier = Modifier.fillMaxWidth()) {
            symbols.forEach { symbol ->
                Text(
                    text = symbol,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    modifier = Modifier.weight(1f),
                )
            }
        }

        // Grid
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            if (isExpanded) {
                weeks.forEach { week ->
                    WeekRow(
                        week = week,
                        selectedDate = selectedDate,
                        intensityByDay = intensityByDay,
                        highlighted = isSelectedWeek(week, selectedDate),
                        onSelect = onSelect,
                    )
                }
            } else {
                WeekRow(
                    week = selectedWeek,
                    selectedDate = selectedDate,
                    intensityByDay = intensityByDay,
                    highlighted = false,
                    onSelect = onSelect,
                )
            }
        }
    }
}

private fun isSelectedWeek(week: List<CalendarDay>, selectedDate: LocalDate): Boolean {
    val rowMonday = week.firstOrNull()?.date ?: return false
    return rowMonday == AppWeek.startOfWeek(selectedDate)
}

@Composable
private fun WeekRow(
    week: List<CalendarDay>,
    selectedDate: LocalDate,
    intensityByDay: Map<LocalDate, Int>,
    highlighted: Boolean,
    onSelect: (LocalDate) -> Unit,
) {
    val highlightModifier = if (highlighted) {
        Modifier
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.08f), RoundedCornerShape(10.dp))
            .border(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.35f), RoundedCornerShape(10.dp))
    } else {
        Modifier
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(highlightModifier)
            .padding(vertical = 2.dp),
    ) {
        week.forEach { day ->
            CalendarDayCell(
                day = day,
                isToday = day.date == LocalDate.now(),
                isSelected = day.date == selectedDate,
                intensity = intensityByDay[day.date] ?: 0,
                onClick = { onSelect(day.date) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun CalendarDayCell(
    day: CalendarDay,
    isToday: Boolean,
    isSelected: Boolean,
    intensity: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val brand = MaterialTheme.colorScheme.primary
    val numberColor = when {
        isSelected -> MaterialTheme.colorScheme.onPrimary
        isToday -> brand
        day.isInDisplayedMonth -> MaterialTheme.colorScheme.onSurface
        else -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    }

    // Intensity dot: bigger/more opaque the more muscles trained. Hidden on the selected day.
    val clamped = intensity.coerceIn(0, 4)
    val dotSize = (4 + clamped).dp
    val dotOpacity = 0.35f + 0.65f * clamped / 4f
    val showDot = intensity > 0 && !isSelected

    Column(
        modifier = modifier
            .clickable(onClick = onClick)
            .padding(vertical = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .then(
                    when {
                        isSelected -> Modifier.background(brand, CircleShape)
                        isToday -> Modifier.border(1.5.dp, brand, CircleShape)
                        else -> Modifier
                    }
                ),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "${day.date.dayOfMonth}",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isSelected || isToday) FontWeight.SemiBold else FontWeight.Normal,
                color = numberColor,
            )
        }
        // Fixed 8dp slot keeps every row vertically aligned.
        Box(modifier = Modifier.height(8.dp), contentAlignment = Alignment.Center) {
            if (showDot) {
                Box(
                    modifier = Modifier
                        .size(dotSize)
                        .background(brand.copy(alpha = dotOpacity), CircleShape),
                )
            }
        }
    }
}

// MARK: - Week detail

@Composable
private fun WeekDetailSection(
    days: List<DayActivities>,
    customCategories: List<CustomCategory>,
    weightUnit: WeightUnit,
) {
    if (days.isEmpty()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.EventBusy,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(40.dp),
            )
            Text(
                text = stringResource(R.string.history_week_empty_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.history_week_empty_description),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        return
    }

    val context = LocalContext.current
    val dayFormatter = remember { DateTimeFormatter.ofPattern("EEEE d", Locale.getDefault()) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        days.forEach { day ->
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = dayFormatter.format(day.date)
                        .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() },
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary,
                )
                day.activities.forEach { activity ->
                    val tracksWeight = remember(activity.entry.category, customCategories) {
                        CategoryResolver.resolve(activity.entry.category, customCategories, context).tracksWeight
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Icon(
                            imageVector = AppIcons.forKey(activity.entry.icon),
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(20.dp),
                        )
                        Text(activity.entry.name, style = MaterialTheme.typography.bodyLarge)
                        if (tracksWeight && activity.weightKg != null) {
                            Text(
                                text = "${weightUnit.displayValue(activity.weightKg).roundToInt()} ${weightUnit.displayLabel}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}
