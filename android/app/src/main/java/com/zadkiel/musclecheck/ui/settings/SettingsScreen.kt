package com.zadkiel.musclecheck.ui.settings

import android.Manifest
import android.os.Build
import android.text.format.DateFormat
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.BuildConfig
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.WeightUnit
import com.zadkiel.musclecheck.notifications.ReminderScheduler
import com.zadkiel.musclecheck.ui.icons.AppIcons
import com.zadkiel.musclecheck.ui.theme.LocalAccents
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import javax.inject.Inject

data class SettingsUiState(
    val appTheme: Int = 0,
    val weightUnit: WeightUnit = WeightUnit.KG,
    val addedPresets: Set<String> = emptySet(),
    val notificationsEnabled: Boolean = false,
    val reminderTime: LocalTime = LocalTime.of(18, 0),
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val prefs: UserPreferencesRepository,
    private val repository: MuscleRepository,
    private val reminderScheduler: ReminderScheduler,
) : ViewModel() {

    val uiState: StateFlow<SettingsUiState> = combine(
        prefs.appTheme,
        prefs.weightUnit,
        prefs.addedActivityPresets,
        prefs.notificationsEnabled,
        prefs.reminderTime,
    ) { theme, unit, presets, notificationsEnabled, reminderTime ->
        SettingsUiState(
            appTheme = theme,
            weightUnit = unit,
            addedPresets = presets,
            notificationsEnabled = notificationsEnabled,
            reminderTime = reminderTime,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsUiState())

    fun setTheme(value: Int) {
        viewModelScope.launch { prefs.setAppTheme(value) }
    }

    fun setWeightUnit(unit: WeightUnit) {
        viewModelScope.launch { prefs.setWeightUnit(unit) }
    }

    fun addPresetEntries(category: ActivityCategory) {
        viewModelScope.launch { repository.addPresetEntries(category) }
    }

    /** Call only after the POST_NOTIFICATIONS permission is granted (or not needed). */
    fun setNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            prefs.setNotificationsEnabled(enabled)
            if (enabled) {
                val time = prefs.reminderTime.first()
                reminderScheduler.scheduleDailyReminder(time.hour, time.minute)
            } else {
                reminderScheduler.cancelAll()
            }
        }
    }

    fun setReminderTime(hour: Int, minute: Int) {
        viewModelScope.launch {
            prefs.setReminderTime(hour, minute)
            if (prefs.notificationsEnabled.first()) {
                reminderScheduler.scheduleDailyReminder(hour, minute)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onOpenCategories: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val accents = LocalAccents.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_title)) },
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
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            // Appearance
            SettingsSection(title = stringResource(R.string.settings_section_appearance)) {
                var themeMenuExpanded by remember { mutableStateOf(false) }
                val themeLabel = when (state.appTheme) {
                    1 -> stringResource(R.string.settings_theme_light)
                    2 -> stringResource(R.string.settings_theme_dark)
                    else -> stringResource(R.string.settings_theme_system)
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { themeMenuExpanded = true }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(stringResource(R.string.settings_theme), modifier = Modifier.weight(1f))
                    Text(themeLabel, color = MaterialTheme.colorScheme.primary)
                    DropdownMenu(expanded = themeMenuExpanded, onDismissRequest = { themeMenuExpanded = false }) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.settings_theme_system)) },
                            onClick = { viewModel.setTheme(0); themeMenuExpanded = false },
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.settings_theme_light)) },
                            onClick = { viewModel.setTheme(1); themeMenuExpanded = false },
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.settings_theme_dark)) },
                            onClick = { viewModel.setTheme(2); themeMenuExpanded = false },
                        )
                    }
                }
            }

            // Activity presets
            SettingsSection(title = stringResource(R.string.settings_section_activity_presets)) {
                ActivityCategory.entries.filter { it != ActivityCategory.CUSTOM }.forEach { category ->
                    val added = category.id in state.addedPresets
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(enabled = !added) { viewModel.addPresetEntries(category) }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            imageVector = AppIcons.forKey(category.defaultIcon),
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(22.dp),
                        )
                        Spacer(Modifier.width(12.dp))
                        Text(stringResource(category.displayNameRes), modifier = Modifier.weight(1f))
                        Icon(
                            imageVector = if (added) Icons.Filled.CheckCircle else Icons.Filled.AddCircleOutline,
                            contentDescription = null,
                            tint = if (added) accents.success else MaterialTheme.colorScheme.primary,
                        )
                    }
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpenCategories() }
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        imageVector = Icons.Filled.CreateNewFolder,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(22.dp),
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        text = stringResource(R.string.settings_custom_categories),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.weight(1f),
                    )
                    Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            // Units
            SettingsSection(title = stringResource(R.string.settings_section_units)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(stringResource(R.string.settings_weight_unit))
                    Spacer(Modifier.padding(4.dp))
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        WeightUnit.entries.forEachIndexed { index, unit ->
                            SegmentedButton(
                                selected = state.weightUnit == unit,
                                onClick = { viewModel.setWeightUnit(unit) },
                                shape = SegmentedButtonDefaults.itemShape(index = index, count = WeightUnit.entries.size),
                            ) {
                                Text(unit.displayLabel)
                            }
                        }
                    }
                }
            }

            // Notifications
            SettingsSection(title = stringResource(R.string.settings_section_notifications)) {
                val permissionLauncher = rememberLauncherForActivityResult(
                    ActivityResultContracts.RequestPermission(),
                ) { granted ->
                    if (granted) viewModel.setNotificationsEnabled(true)
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        stringResource(R.string.settings_notifications_enabled),
                        modifier = Modifier.weight(1f),
                    )
                    Switch(
                        checked = state.notificationsEnabled,
                        onCheckedChange = { enabled ->
                            if (!enabled) {
                                viewModel.setNotificationsEnabled(false)
                            } else if (Build.VERSION.SDK_INT >= 33) {
                                permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                viewModel.setNotificationsEnabled(true)
                            }
                        },
                    )
                }
                if (state.notificationsEnabled) {
                    var showTimePicker by remember { mutableStateOf(false) }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { showTimePicker = true }
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            stringResource(R.string.settings_reminder_time),
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            state.reminderTime.format(
                                DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT),
                            ),
                            color = MaterialTheme.colorScheme.primary,
                        )
                    }
                    if (showTimePicker) {
                        ReminderTimePickerDialog(
                            initialTime = state.reminderTime,
                            onConfirm = { hour, minute ->
                                viewModel.setReminderTime(hour, minute)
                                showTimePicker = false
                            },
                            onDismiss = { showTimePicker = false },
                        )
                    }
                }
            }

            // About
            SettingsSection(title = stringResource(R.string.settings_section_about)) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                ) {
                    Text(stringResource(R.string.settings_version), modifier = Modifier.weight(1f))
                    Text(BuildConfig.VERSION_NAME, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReminderTimePickerDialog(
    initialTime: LocalTime,
    onConfirm: (hour: Int, minute: Int) -> Unit,
    onDismiss: () -> Unit,
) {
    val timeState = rememberTimePickerState(
        initialHour = initialTime.hour,
        initialMinute = initialTime.minute,
        is24Hour = DateFormat.is24HourFormat(LocalContext.current),
    )
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = { onConfirm(timeState.hour, timeState.minute) }) {
                Text(stringResource(android.R.string.ok))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(android.R.string.cancel))
            }
        },
        text = { TimePicker(state = timeState) },
    )
}

@Composable
fun SettingsSection(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp)),
        ) {
            content()
        }
    }
}
