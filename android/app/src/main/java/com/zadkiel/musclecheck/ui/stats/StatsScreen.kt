package com.zadkiel.musclecheck.ui.stats

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.MuscleFrequency
import com.zadkiel.musclecheck.domain.StatsCalculator
import com.zadkiel.musclecheck.domain.WeeklyCount
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import java.util.Locale
import javax.inject.Inject

data class StatsUiState(
    val totalDaysTrained: Int = 0,
    val averageDaysPerWeek: Double = 0.0,
    val weeklyData: List<WeeklyCount> = emptyList(),
    val muscleFrequency: List<MuscleFrequency> = emptyList(),
) {
    val hasData: Boolean get() = weeklyData.any { it.count > 0 } || muscleFrequency.isNotEmpty()
}

@HiltViewModel
class StatsViewModel @Inject constructor(
    repository: MuscleRepository,
) : ViewModel() {
    val uiState: StateFlow<StatsUiState> = repository.entries.map { entries ->
        StatsUiState(
            totalDaysTrained = StatsCalculator.totalDaysTrained(entries),
            averageDaysPerWeek = StatsCalculator.averageTrainingDaysPerWeek(entries),
            weeklyData = StatsCalculator.daysTrainedPerWeek(entries),
            muscleFrequency = StatsCalculator.frequencyByMuscle(entries),
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), StatsUiState())
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsScreen(
    onBack: () -> Unit,
    viewModel: StatsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.stats_title)) },
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Summary cards
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                SummaryCard(
                    title = stringResource(R.string.stats_total_days),
                    value = "${state.totalDaysTrained}",
                    icon = Icons.Filled.EventAvailable,
                    modifier = Modifier.weight(1f),
                )
                SummaryCard(
                    title = stringResource(R.string.stats_avg_per_week),
                    value = String.format(Locale.getDefault(), "%.1f", state.averageDaysPerWeek),
                    icon = Icons.Filled.BarChart,
                    modifier = Modifier.weight(1f),
                )
            }

            if (state.weeklyData.any { it.count > 0 }) {
                ChartCard(title = stringResource(R.string.stats_weekly_title)) {
                    WeeklyTrainingChart(data = state.weeklyData)
                }
            }

            if (state.muscleFrequency.isNotEmpty()) {
                ChartCard(title = stringResource(R.string.stats_muscle_frequency_title)) {
                    MuscleFrequencyChart(data = state.muscleFrequency)
                }
            }

            if (!state.hasData) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 60.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        imageVector = Icons.Filled.BarChart,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(40.dp),
                    )
                    Text(stringResource(R.string.stats_no_data_title), style = MaterialTheme.typography.titleMedium)
                    Text(
                        text = stringResource(R.string.stats_no_data_description),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                    )
                }
            }
        }
    }
}

@Composable
private fun SummaryCard(title: String, value: String, icon: ImageVector, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(14.dp),
            )
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Text(
            text = value,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun ChartCard(title: String, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        content()
    }
}

/**
 * Single-series column chart: unique training days per week, last 8 weeks.
 * One hue (brand); values labeled in text ink above each bar; no legend needed.
 */
@Composable
private fun WeeklyTrainingChart(data: List<WeeklyCount>) {
    val maxCount = maxOf(data.maxOfOrNull { it.count } ?: 0, 7)
    val barArea = 120.dp

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(barArea + 40.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        data.forEach { week ->
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Bottom,
            ) {
                if (week.count > 0) {
                    Text(
                        text = "${week.count}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.height(2.dp))
                    Box(
                        modifier = Modifier
                            .width(16.dp)
                            .height(barArea * week.count / maxCount)
                            .background(
                                MaterialTheme.colorScheme.primary,
                                RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp),
                            ),
                    )
                } else {
                    // Baseline tick so empty weeks still read as part of the series.
                    Box(
                        modifier = Modifier
                            .width(16.dp)
                            .height(2.dp)
                            .background(MaterialTheme.colorScheme.outlineVariant),
                    )
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    text = week.weekLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Clip,
                )
            }
        }
    }
}

/**
 * Single-series horizontal bars: unique training days per muscle, sorted descending.
 * Name and value stay in text ink; the bar alone carries the brand hue.
 */
@Composable
private fun MuscleFrequencyChart(data: List<MuscleFrequency>) {
    val maxCount = (data.maxOfOrNull { it.count } ?: 1).coerceAtLeast(1)
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        data.forEach { item ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = item.muscle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.width(96.dp),
                )
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(14.dp),
                    contentAlignment = Alignment.CenterStart,
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(item.count.toFloat() / maxCount)
                            .height(14.dp)
                            .background(
                                MaterialTheme.colorScheme.primary,
                                RoundedCornerShape(topEnd = 4.dp, bottomEnd = 4.dp),
                            ),
                    )
                }
                Text(
                    text = "${item.count}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.width(24.dp),
                    textAlign = TextAlign.End,
                )
            }
        }
    }
}
