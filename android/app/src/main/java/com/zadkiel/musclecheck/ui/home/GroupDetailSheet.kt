package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WeightUnit
import com.zadkiel.musclecheck.ui.icons.AppIcons

/**
 * Opened by tapping a group's NAME (for groups whose metric logs something). Lists the
 * group's exercises with their last values; tap one to edit, or add a new one.
 *
 * The weekly CHECK stays on the home row — coming in here is never required to mark the
 * group trained. Logging an exercise here also marks the group trained today.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupDetailSheet(
    entry: MuscleEntry,
    groupMetric: MetricType,
    weightUnit: WeightUnit,
    onExerciseClick: (Exercise) -> Unit,
    onAddExercise: (name: String, metric: MetricType, icon: String) -> Unit,
    onDeleteExercise: (Exercise) -> Unit,
    onDismiss: () -> Unit,
) {
    var adding by remember { mutableStateOf(false) }
    var pendingDelete by remember { mutableStateOf<Exercise?>(null) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
        ) {
            Text(
                text = entry.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(16.dp))

            if (entry.exercises.isEmpty()) {
                Text(
                    text = stringResource(R.string.group_no_exercises, entry.name),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 8.dp),
                )
            } else {
                // Capped so a long list doesn't push the "add" action off the sheet.
                LazyColumn(modifier = Modifier.heightIn(max = 420.dp)) {
                    items(entry.exercises, key = { it.id }) { exercise ->
                        ExerciseRow(
                            exercise = exercise,
                            weightUnit = weightUnit,
                            onClick = { onExerciseClick(exercise) },
                            onDelete = { pendingDelete = exercise },
                        )
                        HorizontalDivider()
                    }
                }
            }

            Spacer(Modifier.height(8.dp))
            TextButton(onClick = { adding = true }) {
                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.size(8.dp))
                Text(stringResource(R.string.group_add_exercise))
            }
        }
    }

    if (adding) {
        AddExerciseToGroupDialog(
            defaultMetric = if (groupMetric == MetricType.NONE) MetricType.STRENGTH else groupMetric,
            defaultIcon = entry.icon,
            onAdd = { name, metric, icon ->
                onAddExercise(name, metric, icon)
                adding = false
            },
            onDismiss = { adding = false },
        )
    }

    pendingDelete?.let { exercise ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text(stringResource(R.string.delete_entry_title)) },
            text = { Text(stringResource(R.string.delete_entry_message, exercise.name)) },
            confirmButton = {
                TextButton(onClick = {
                    onDeleteExercise(exercise)
                    pendingDelete = null
                }) { Text(stringResource(R.string.delete)) }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text(stringResource(R.string.cancel)) }
            },
        )
    }
}

@Composable
private fun ExerciseRow(
    exercise: Exercise,
    weightUnit: WeightUnit,
    onClick: () -> Unit,
    onDelete: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = AppIcons.forKey(exercise.icon),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp),
        )
        Spacer(Modifier.size(12.dp))
        Text(text = exercise.name, style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.weight(1f))
        exercise.summary(weightUnit)?.let { summary ->
            Text(
                text = summary,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        IconButton(onClick = onDelete) {
            Icon(
                Icons.Filled.Delete,
                contentDescription = stringResource(R.string.delete),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp),
            )
        }
        Icon(
            Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(18.dp),
        )
    }
}

/**
 * Create an exercise inside the current group. Metric/icon default to the group's; the
 * name is the only required field.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddExerciseToGroupDialog(
    defaultMetric: MetricType,
    defaultIcon: String,
    onAdd: (String, MetricType, String) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var metric by remember { mutableStateOf(defaultMetric) }
    var menuExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.imePadding(),
        title = { Text(stringResource(R.string.group_add_exercise)) },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(stringResource(R.string.group_exercise_name_placeholder)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
                ExposedDropdownMenuBox(
                    expanded = menuExpanded,
                    onExpandedChange = { menuExpanded = it },
                ) {
                    OutlinedTextField(
                        value = stringResource(metric.displayNameRes),
                        onValueChange = {},
                        readOnly = true,
                        label = { Text(stringResource(R.string.add_metric_question)) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = menuExpanded) },
                        modifier = Modifier
                            .menuAnchor(androidx.compose.material3.MenuAnchorType.PrimaryNotEditable)
                            .fillMaxWidth(),
                    )
                    ExposedDropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
                        MetricType.entries.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(stringResource(option.displayNameRes)) },
                                onClick = {
                                    metric = option
                                    menuExpanded = false
                                },
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onAdd(name, metric, defaultIcon) },
                enabled = name.isNotBlank(),
            ) { Text(stringResource(R.string.add_create_confirm)) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) }
        },
    )
}
