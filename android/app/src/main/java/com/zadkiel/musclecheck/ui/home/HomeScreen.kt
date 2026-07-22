package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WeightUnit
import com.zadkiel.musclecheck.ui.icons.AppIcons
import com.zadkiel.musclecheck.ui.theme.LocalAccents
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onOpenHistory: () -> Unit,
    onOpenStats: () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenProgress: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val addError by viewModel.addError.collectAsStateWithLifecycle()

    var showAddSheet by remember { mutableStateOf(false) }
    var sessionEntry by remember { mutableStateOf<MuscleEntry?>(null) }
    var entryToDelete by remember { mutableStateOf<MuscleEntry?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.home_title)) },
                navigationIcon = {
                    TextButton(onClick = onOpenHistory) {
                        Text(stringResource(R.string.navigation_history_button))
                    }
                },
                actions = {
                    IconButton(onClick = { showAddSheet = true }) {
                        Icon(Icons.Filled.AddCircleOutline, contentDescription = stringResource(R.string.add_new_muscle_group))
                    }
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = stringResource(R.string.settings_title))
                    }
                    IconButton(onClick = onOpenStats) {
                        Icon(Icons.Filled.BarChart, contentDescription = stringResource(R.string.stats_title))
                    }
                    IconButton(onClick = onOpenProgress) {
                        Icon(Icons.Filled.PhotoCamera, contentDescription = stringResource(R.string.progress_photos_title))
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            StreakCard(
                currentStreak = state.currentStreak,
                maxStreak = state.maxStreak,
                isAlive = state.isStreakAlive,
            )
            Spacer(Modifier.height(16.dp))

            if (state.loaded && state.isEmpty) {
                EmptyState()
            } else {
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    val showHeaders = state.groups.size > 1
                    state.groups.forEach { group ->
                        if (showHeaders) {
                            item(key = "header-${group.category}") {
                                CategoryHeader(group.category, state.customCategories)
                            }
                        }
                        items(count = group.entries.size, key = { group.entries[it].id }) { index ->
                            val entry = group.entries[index]
                            MuscleEntryRow(
                                entry = entry,
                                customCategories = state.customCategories,
                                weightUnit = state.weightUnit,
                                onToggle = { viewModel.toggleActivity(entry) },
                                onOpenSession = { sessionEntry = entry },
                                onLongPress = { entryToDelete = entry },
                            )
                            if (index < group.entries.lastIndex) {
                                HorizontalDivider(modifier = Modifier.padding(start = 64.dp))
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddSheet) {
        AddEntrySheet(
            customCategories = state.customCategories,
            errorMessage = addError,
            onSave = { name, category, icon ->
                viewModel.addEntry(name, category, icon) { showAddSheet = false }
            },
            onDismiss = {
                viewModel.clearAddError()
                showAddSheet = false
            },
        )
    }

    sessionEntry?.let { entry ->
        SessionLogSheet(
            entry = entry,
            weightUnit = state.weightUnit,
            onSave = { weightKg, sets, reps ->
                viewModel.saveSession(entry, weightKg, sets, reps)
                sessionEntry = null
            },
            onDismiss = { sessionEntry = null },
        )
    }

    entryToDelete?.let { entry ->
        AlertDialog(
            onDismissRequest = { entryToDelete = null },
            title = { Text(stringResource(R.string.delete_entry_title)) },
            text = { Text(stringResource(R.string.delete_entry_message, entry.name)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteEntry(entry)
                    entryToDelete = null
                }) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { entryToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            },
        )
    }
}

// MARK: - Streak card

@Composable
fun StreakCard(currentStreak: Int, maxStreak: Int, isAlive: Boolean) {
    val accents = LocalAccents.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .padding(vertical = 12.dp, horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(
                    imageVector = if (isAlive) Icons.Filled.LocalFireDepartment else Icons.Filled.NightsStay,
                    contentDescription = null,
                    tint = if (isAlive) accents.streak else MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(24.dp),
                )
                Text(
                    text = "$currentStreak",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isAlive) accents.streak else MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                text = stringResource(R.string.streak_current),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        VerticalDivider(modifier = Modifier.height(40.dp))

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(
                    imageVector = Icons.Filled.EmojiEvents,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(24.dp),
                )
                Text(
                    text = "$maxStreak",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                text = stringResource(R.string.streak_max),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// MARK: - Category header

@Composable
private fun CategoryHeader(categoryRaw: String, customCategories: List<CustomCategory>) {
    val context = LocalContext.current
    val resolved = remember(categoryRaw, customCategories) {
        CategoryResolver.resolve(categoryRaw, customCategories, context)
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(
            imageVector = AppIcons.forKey(resolved.icon),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(18.dp),
        )
        Text(
            text = resolved.displayName,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

// MARK: - Entry row

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MuscleEntryRow(
    entry: MuscleEntry,
    customCategories: List<CustomCategory>,
    weightUnit: WeightUnit,
    onToggle: () -> Unit,
    onOpenSession: () -> Unit,
    onLongPress: () -> Unit,
) {
    val context = LocalContext.current
    val accents = LocalAccents.current
    val tracksWeight = remember(entry.category, customCategories) {
        CategoryResolver.resolve(entry.category, customCategories, context).tracksWeight
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = { if (tracksWeight) onOpenSession() },
                onLongClick = onLongPress,
            )
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Icon in a soft tinted tile, mirroring the iOS row.
        Box(
            modifier = Modifier
                .size(32.dp)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), RoundedCornerShape(8.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = AppIcons.forKey(entry.icon),
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(12.dp))
        Text(entry.name, style = MaterialTheme.typography.bodyLarge)

        if (tracksWeight) {
            entry.lastWeightKg?.let { kg ->
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "${weightUnit.displayValue(kg).roundToInt()} ${weightUnit.displayLabel}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Spacer(Modifier.weight(1f))

        IconButton(onClick = onToggle) {
            Icon(
                imageVector = if (entry.isChecked) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
                contentDescription = stringResource(if (entry.isChecked) R.string.checked_today else R.string.not_checked),
                tint = if (entry.isChecked) accents.success else MaterialTheme.colorScheme.outline,
            )
        }
    }
}

// MARK: - Empty state

@Composable
private fun EmptyState() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = stringResource(R.string.empty_state_message),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
