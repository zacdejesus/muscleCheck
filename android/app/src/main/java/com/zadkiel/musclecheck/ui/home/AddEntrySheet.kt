package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.ui.icons.AppIcons

/**
 * Unified add flow, as a PICKER rather than a form (recognition over recall): category
 * chips on top, tappable rows of that category's presets below — tap = added, with the
 * row flipping to a check so multi-add needs no trips back and forth. Free-text names
 * live behind "create your own", and a new category can be created inline.
 *
 * Port of the iOS `AddExerciseView` (Feature 18).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEntrySheet(
    entries: List<MuscleEntry>,
    customCategories: List<CustomCategory>,
    errorMessage: String?,
    /** Last category used, so the sheet reopens where the user left off. */
    initialCategoryId: String,
    onCategorySelected: (String) -> Unit,
    onAddPreset: (ActivityCategory, Int, String) -> Unit,
    onAddCustom: (name: String, category: String, icon: String, metric: MetricType) -> Unit,
    onRemoveEntry: (MuscleEntry) -> Unit,
    onCreateCategory: (name: String, icon: String, metric: MetricType) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    var selectedCategoryId by remember { mutableStateOf(initialCategoryId) }
    var creatingOwn by remember { mutableStateOf(false) }
    var creatingCategory by remember { mutableStateOf(false) }

    val builtIn = remember(selectedCategoryId) { ActivityCategory.fromId(selectedCategoryId) }
    val isGym = builtIn == ActivityCategory.GYM

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
        ) {
            Text(
                text = stringResource(R.string.add_sheet_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )
            Spacer(Modifier.height(16.dp))

            // Category chips.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                ActivityCategory.entries.filter { it != ActivityCategory.CUSTOM }.forEach { category ->
                    CategoryChip(
                        name = stringResource(category.displayNameRes),
                        icon = category.defaultIcon,
                        selected = selectedCategoryId == category.id,
                        onClick = {
                            selectedCategoryId = category.id
                            onCategorySelected(category.id)
                        },
                    )
                }
                customCategories.forEach { category ->
                    CategoryChip(
                        name = category.name,
                        icon = category.icon,
                        selected = selectedCategoryId == category.id,
                        onClick = {
                            selectedCategoryId = category.id
                            onCategorySelected(category.id)
                        },
                    )
                }
                CategoryChip(
                    name = stringResource(R.string.add_new_category_option),
                    icon = "star.fill",
                    selected = false,
                    onClick = { creatingCategory = true },
                )
            }

            Spacer(Modifier.height(16.dp))
            Text(
                text = stringResource(
                    if (isGym) R.string.add_picker_prompt_gym else R.string.add_picker_prompt_generic
                ),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(8.dp))

            // Preset rows for the selected category + the user's own entries in it.
            val presets = builtIn?.presetEntries.orEmpty()
            val ownEntries = entries.filter { it.category == selectedCategoryId }
            val presetNames = presets.map { context.getString(it.nameRes) }.toSet()
            val rows = presets.map { preset ->
                val name = context.getString(preset.nameRes)
                PickerRow(
                    key = "preset-$name",
                    name = name,
                    icon = preset.icon,
                    existing = ownEntries.firstOrNull { it.name.equals(name, ignoreCase = true) },
                    preset = preset.nameRes to preset.icon,
                )
            } + ownEntries.filterNot { presetNames.any { p -> p.equals(it.name, ignoreCase = true) } }
                .map { entry ->
                    PickerRow(key = "own-${entry.id}", name = entry.name, icon = entry.icon, existing = entry)
                }

            if (rows.isEmpty()) {
                Text(
                    text = stringResource(R.string.add_picker_all_added),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 12.dp),
                )
            } else {
                LazyColumn(modifier = Modifier.heightIn(max = 320.dp)) {
                    items(rows, key = { it.key }) { row ->
                        PickerRowItem(
                            row = row,
                            onAdd = {
                                val preset = row.preset
                                if (preset != null && builtIn != null) {
                                    onAddPreset(builtIn, preset.first, preset.second)
                                }
                            },
                            onRemove = { row.existing?.let(onRemoveEntry) },
                        )
                    }
                }
            }

            errorMessage?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }

            Spacer(Modifier.height(8.dp))
            TextButton(onClick = { creatingOwn = true }) {
                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.size(8.dp))
                Text(
                    stringResource(
                        if (isGym) R.string.add_create_custom_gym else R.string.add_create_custom_generic
                    )
                )
            }

            Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.add_done))
            }
        }
    }

    if (creatingOwn) {
        val defaultMetric = builtIn?.defaultMetric
            ?: customCategories.firstOrNull { it.id == selectedCategoryId }?.defaultMetric
            ?: MetricType.NONE
        CreateOwnDialog(
            isGym = isGym,
            defaultMetric = defaultMetric,
            defaultIcon = builtIn?.defaultIcon
                ?: customCategories.firstOrNull { it.id == selectedCategoryId }?.icon
                ?: ActivityCategory.CUSTOM.defaultIcon,
            onAdd = { name, metric, icon ->
                onAddCustom(name, selectedCategoryId, icon, metric)
                creatingOwn = false
            },
            onDismiss = { creatingOwn = false },
        )
    }

    if (creatingCategory) {
        CreateCategoryDialog(
            onAdd = { name, icon, metric ->
                onCreateCategory(name, icon, metric)
                creatingCategory = false
            },
            onDismiss = { creatingCategory = false },
        )
    }
}

private data class PickerRow(
    val key: String,
    val name: String,
    val icon: String,
    val existing: MuscleEntry?,
    /** (nameRes, icon) when this row comes from a built-in preset. */
    val preset: Pair<Int, String>? = null,
)

@Composable
private fun PickerRowItem(row: PickerRow, onAdd: () -> Unit, onRemove: () -> Unit) {
    val inList = row.existing != null
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { if (inList) onRemove() else onAdd() }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = AppIcons.forKey(row.icon),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp),
        )
        Spacer(Modifier.size(12.dp))
        Text(row.name, style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.weight(1f))
        if (inList) {
            Text(
                text = stringResource(R.string.add_in_your_list),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.size(8.dp))
            Icon(
                Icons.Filled.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp),
            )
        } else {
            Icon(
                Icons.Filled.Add,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

@Composable
private fun CategoryChip(name: String, icon: String, selected: Boolean, onClick: () -> Unit) {
    val background = if (selected) MaterialTheme.colorScheme.primary else Color.Transparent
    val content = if (selected) {
        MaterialTheme.colorScheme.onPrimary
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }
    Row(
        modifier = Modifier
            .background(background, RoundedCornerShape(20.dp))
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = AppIcons.forKey(icon),
            contentDescription = null,
            tint = content,
            modifier = Modifier.size(18.dp),
        )
        Spacer(Modifier.size(6.dp))
        Text(name, style = MaterialTheme.typography.labelLarge, color = content)
    }
}

/** Escape hatch for names outside the presets; category is inherited from the chip. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreateOwnDialog(
    isGym: Boolean,
    defaultMetric: MetricType,
    defaultIcon: String,
    onAdd: (String, MetricType, String) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var metric by remember { mutableStateOf(defaultMetric) }
    var icon by remember { mutableStateOf(defaultIcon) }

    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.imePadding(),
        title = {
            Text(
                stringResource(
                    if (isGym) R.string.add_create_custom_title_gym else R.string.add_create_custom_title
                )
            )
        },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = {
                        Text(
                            stringResource(
                                if (isGym) R.string.add_name_placeholder_gym
                                else R.string.add_name_placeholder_generic
                            )
                        )
                    },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
                MetricDropdown(metric = metric, onMetricChange = { metric = it })
                Spacer(Modifier.height(12.dp))
                IconPickerRow(selected = icon, onSelect = { icon = it })
            }
        },
        confirmButton = {
            Button(onClick = { onAdd(name, metric, icon) }, enabled = name.isNotBlank()) {
                Text(stringResource(R.string.add_create_confirm))
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}

/** Create a category without leaving the add flow (same store as Settings). */
@Composable
private fun CreateCategoryDialog(
    onAdd: (String, String, MetricType) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var icon by remember { mutableStateOf(ActivityCategory.CUSTOM.defaultIcon) }
    var metric by remember { mutableStateOf(MetricType.NONE) }

    AlertDialog(
        onDismissRequest = onDismiss,
        modifier = Modifier.imePadding(),
        title = { Text(stringResource(R.string.custom_category_section_new)) },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(stringResource(R.string.custom_category_name_placeholder)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
                MetricDropdown(metric = metric, onMetricChange = { metric = it })
                Spacer(Modifier.height(12.dp))
                IconPickerRow(selected = icon, onSelect = { icon = it })
            }
        },
        confirmButton = {
            Button(onClick = { onAdd(name, icon, metric) }, enabled = name.isNotBlank()) {
                Text(stringResource(R.string.custom_category_add))
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun MetricDropdown(metric: MetricType, onMetricChange: (MetricType) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
        OutlinedTextField(
            value = stringResource(metric.displayNameRes),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.add_metric_question)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth(),
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            MetricType.entries.forEach { option ->
                DropdownMenuItem(
                    text = { Text(stringResource(option.displayNameRes)) },
                    onClick = {
                        onMetricChange(option)
                        expanded = false
                    },
                )
            }
        }
    }
}

/** Compact horizontal icon picker (the full grid lives in Settings). */
@Composable
private fun IconPickerRow(selected: String, onSelect: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        ActivityCategory.availableIcons.forEach { key ->
            val isSelected = key == selected
            Icon(
                imageVector = AppIcons.forKey(key),
                contentDescription = null,
                tint = if (isSelected) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                modifier = Modifier
                    .background(
                        if (isSelected) MaterialTheme.colorScheme.primaryContainer else Color.Transparent,
                        RoundedCornerShape(8.dp),
                    )
                    .clickable { onSelect(key) }
                    .padding(8.dp)
                    .size(24.dp),
            )
        }
    }
}
