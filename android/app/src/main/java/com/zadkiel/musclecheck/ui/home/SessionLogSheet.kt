package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedIconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.Exercise
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.SessionInput
import com.zadkiel.musclecheck.domain.model.WeightUnit
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

/**
 * What [SessionLogSheet] edits — decoupled from MuscleEntry so it can drive an exercise
 * (the detail layer) or a group. Prefill values are pre-resolved by the caller; for
 * distanceDuration, distance + duration come from the SAME session so a distance from
 * one day and a time from another are never paired as if done together.
 */
data class SessionLogTarget(
    val title: String,
    val metric: MetricType,
    val lastWeightKg: Double? = null,
    val lastSets: Int? = null,
    val lastReps: Int? = null,
    val lastDurationSeconds: Int? = null,
    val lastDistanceMeters: Double? = null,
    val lastTrained: LocalDate? = null,
) {
    companion object {
        fun of(exercise: Exercise): SessionLogTarget {
            val cardio = exercise.lastDistanceDurationSession
            return SessionLogTarget(
                title = exercise.name,
                metric = exercise.metric,
                lastWeightKg = exercise.lastWeightKg,
                lastSets = exercise.lastSets,
                lastReps = exercise.lastReps,
                lastDurationSeconds = if (exercise.metric == MetricType.DISTANCE_DURATION) {
                    cardio?.durationSeconds
                } else {
                    exercise.lastDurationSeconds
                },
                lastDistanceMeters = cardio?.distanceMeters,
                lastTrained = exercise.lastTrainedDate,
            )
        }

        fun of(entry: MuscleEntry, metric: MetricType): SessionLogTarget {
            val cardio = entry.sessions
                .filter { it.distanceMeters != null || it.durationSeconds != null }
                .maxByOrNull { it.date }
            return SessionLogTarget(
                title = entry.name,
                metric = metric,
                lastWeightKg = entry.lastWeightKg,
                lastSets = entry.lastSets,
                lastReps = entry.lastReps,
                lastDurationSeconds = cardio?.durationSeconds,
                lastDistanceMeters = cardio?.distanceMeters,
                lastTrained = entry.lastTrainedDate,
            )
        }
    }
}

/**
 * "Registro" — session editor driven by the target's [MetricType]. Opens calm (no
 * keyboard): the main value is a big tappable number. Strength shows weight + sets/reps
 * steppers; duration shows minutes; distanceDuration shows km with minutes below.
 * Weight is converted to kg at this boundary.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SessionLogSheet(
    target: SessionLogTarget,
    weightUnit: WeightUnit,
    onSave: (SessionInput) -> Unit,
    onDismiss: () -> Unit,
) {
    var weightText by remember(target.title) {
        mutableStateOf(target.lastWeightKg?.let { weightUnit.displayValue(it).roundToInt().toString() } ?: "")
    }
    var sets by remember(target.title) { mutableIntStateOf(target.lastSets ?: 0) }
    var reps by remember(target.title) { mutableIntStateOf(target.lastReps ?: 0) }
    var minutesText by remember(target.title) {
        mutableStateOf(target.lastDurationSeconds?.let { (it / 60).toString() } ?: "")
    }
    var kmText by remember(target.title) {
        mutableStateOf(target.lastDistanceMeters?.let { String.format("%.1f", it / 1000) } ?: "")
    }

    val parsedWeight = weightText.replace(',', '.').toDoubleOrNull()
    val parsedMinutes = minutesText.toIntOrNull()
    val parsedKm = kmText.replace(',', '.').toDoubleOrNull()

    val isValid = when (target.metric) {
        MetricType.NONE -> false // unreachable: rows with no metric don't open the log
        MetricType.STRENGTH -> (parsedWeight ?: 0.0) > 0.0
        MetricType.DURATION -> (parsedMinutes ?: 0) > 0
        // A runner may log only one of the two.
        MetricType.DISTANCE_DURATION -> (parsedKm ?: 0.0) > 0.0 || (parsedMinutes ?: 0) > 0
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                // imePadding + scroll: without them the keyboard covers Save and the
                // sheet becomes a dead end once you type a value.
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = target.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.height(24.dp))

            when (target.metric) {
                MetricType.STRENGTH -> HeroValueField(
                    value = weightText,
                    onValueChange = { weightText = it },
                    unitLabel = weightUnit.displayLabel,
                )
                MetricType.DURATION -> HeroValueField(
                    value = minutesText,
                    onValueChange = { minutesText = it },
                    unitLabel = stringResource(R.string.session_unit_min),
                    decimals = false,
                )
                MetricType.DISTANCE_DURATION -> HeroValueField(
                    value = kmText,
                    onValueChange = { kmText = it },
                    unitLabel = stringResource(R.string.session_unit_km),
                )
                MetricType.NONE -> Unit
            }

            target.lastTrained?.let { last ->
                val formatted = remember(last) {
                    last.format(DateTimeFormatter.ofPattern("EEE d MMM", Locale.getDefault()))
                }
                Text(
                    text = stringResource(R.string.session_last_trained, formatted),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Spacer(Modifier.height(28.dp))

            when (target.metric) {
                MetricType.STRENGTH -> Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    StepperColumn(
                        title = stringResource(R.string.session_field_sets),
                        value = sets,
                        onDecrement = { if (sets > 0) sets-- },
                        onIncrement = { sets++ },
                        modifier = Modifier.weight(1f),
                    )
                    StepperColumn(
                        title = stringResource(R.string.session_field_reps),
                        value = reps,
                        onDecrement = { if (reps > 0) reps-- },
                        onIncrement = { reps++ },
                        modifier = Modifier.weight(1f),
                    )
                }
                MetricType.DISTANCE_DURATION -> OutlinedTextField(
                    value = minutesText,
                    onValueChange = { new -> minutesText = new.filter { it.isDigit() } },
                    label = { Text(stringResource(R.string.session_field_duration)) },
                    suffix = { Text(stringResource(R.string.session_unit_min)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                else -> Unit
            }

            Spacer(Modifier.height(32.dp))

            Button(
                onClick = {
                    onSave(
                        when (target.metric) {
                            MetricType.STRENGTH -> SessionInput(
                                // 0 means "not recorded" → store null to keep the data clean.
                                weightKg = parsedWeight?.let { weightUnit.toKg(it.roundToInt().toDouble()) },
                                sets = sets.takeIf { it > 0 },
                                reps = reps.takeIf { it > 0 },
                            )
                            MetricType.DURATION -> SessionInput(
                                durationSeconds = parsedMinutes?.takeIf { it > 0 }?.times(60),
                            )
                            MetricType.DISTANCE_DURATION -> SessionInput(
                                durationSeconds = parsedMinutes?.takeIf { it > 0 }?.times(60),
                                distanceMeters = parsedKm?.takeIf { it > 0.0 }?.times(1000),
                            )
                            MetricType.NONE -> SessionInput()
                        }
                    )
                },
                enabled = isValid,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.save))
            }
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.cancel))
            }
        }
    }
}

/** The big tappable number that is both the display and the input. */
@Composable
private fun HeroValueField(
    value: String,
    onValueChange: (String) -> Unit,
    unitLabel: String,
    decimals: Boolean = true,
) {
    Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        TextField(
            value = value,
            onValueChange = { new ->
                onValueChange(new.filter { it.isDigit() || (decimals && (it == '.' || it == ',')) })
            },
            placeholder = {
                Text(
                    "0",
                    fontSize = 56.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            },
            textStyle = TextStyle(
                fontSize = 56.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
            ),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
            ),
            modifier = Modifier.width(180.dp),
        )
        Text(
            text = unitLabel,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(bottom = 16.dp),
        )
    }
}

@Composable
private fun StepperColumn(
    title: String,
    value: Int,
    onDecrement: () -> Unit,
    onIncrement: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(12.dp))
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedIconButton(onClick = onDecrement, enabled = value > 0, modifier = Modifier.size(36.dp)) {
                Icon(Icons.Filled.Remove, contentDescription = null, modifier = Modifier.size(18.dp))
            }
            Text(
                text = if (value > 0) "$value" else "–",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
            )
            OutlinedIconButton(onClick = onIncrement, modifier = Modifier.size(36.dp)) {
                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(18.dp))
            }
        }
    }
}
