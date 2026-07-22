package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CategoryResolver
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.ui.icons.AppIcons

/** Port of AddMuscleGroupView: name + category picker + icon grid. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEntrySheet(
    customCategories: List<CustomCategory>,
    errorMessage: String?,
    onSave: (name: String, category: String, icon: String) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    var name by remember { mutableStateOf("") }
    var selectedCategoryId by remember { mutableStateOf(ActivityCategory.GYM.id) }
    var selectedIcon by remember { mutableStateOf(ActivityCategory.GYM.defaultIcon) }
    var categoryMenuExpanded by remember { mutableStateOf(false) }

    val selectedCategoryLabel = remember(selectedCategoryId, customCategories) {
        CategoryResolver.resolve(selectedCategoryId, customCategories, context).displayName
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
        ) {
            Text(
                text = stringResource(R.string.add_exercise),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            )
            Spacer(Modifier.height(20.dp))

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text(stringResource(R.string.new_exercise_placeholder)) },
                label = { Text(stringResource(R.string.add_exercise)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(16.dp))

            ExposedDropdownMenuBox(
                expanded = categoryMenuExpanded,
                onExpandedChange = { categoryMenuExpanded = it },
            ) {
                OutlinedTextField(
                    value = selectedCategoryLabel,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(stringResource(R.string.select_category)) },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryMenuExpanded) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                )
                ExposedDropdownMenu(
                    expanded = categoryMenuExpanded,
                    onDismissRequest = { categoryMenuExpanded = false },
                ) {
                    ActivityCategory.entries.forEach { category ->
                        DropdownMenuItem(
                            text = { Text(stringResource(category.displayNameRes)) },
                            leadingIcon = { Icon(AppIcons.forKey(category.defaultIcon), contentDescription = null) },
                            onClick = {
                                selectedCategoryId = category.id
                                selectedIcon = category.defaultIcon
                                categoryMenuExpanded = false
                            },
                        )
                    }
                    customCategories.forEach { category ->
                        DropdownMenuItem(
                            text = { Text(category.name) },
                            leadingIcon = { Icon(AppIcons.forKey(category.icon), contentDescription = null) },
                            onClick = {
                                selectedCategoryId = category.id
                                selectedIcon = category.icon
                                categoryMenuExpanded = false
                            },
                        )
                    }
                }
            }
            Spacer(Modifier.height(16.dp))

            Text(
                text = stringResource(R.string.select_icon),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(8.dp))
            LazyVerticalGrid(
                columns = GridCells.Fixed(6),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.height(140.dp),
            ) {
                items(ActivityCategory.availableIcons) { icon ->
                    val isSelected = icon == selectedIcon
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .background(
                                if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                else MaterialTheme.colorScheme.surface,
                                RoundedCornerShape(8.dp),
                            )
                            .clickable { selectedIcon = icon },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = AppIcons.forKey(icon),
                            contentDescription = null,
                            tint = if (isSelected) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(22.dp),
                        )
                    }
                }
            }

            errorMessage?.let { message ->
                Spacer(Modifier.height(12.dp))
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                )
            }

            Spacer(Modifier.height(24.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                    Text(stringResource(R.string.cancel))
                }
                Button(
                    onClick = { onSave(name, selectedCategoryId, selectedIcon) },
                    modifier = Modifier.weight(1f),
                ) {
                    Text(stringResource(R.string.save))
                }
            }
        }
    }
}
