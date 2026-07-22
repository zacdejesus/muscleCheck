package com.zadkiel.musclecheck.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedIconButton
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
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.WeightUnit
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

/**
 * "Registro" — session editor. Opens calm (no keyboard): the weight is a big tappable
 * number and sets/reps are steppers. Weight is converted to kg at this boundary.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SessionLogSheet(
    entry: MuscleEntry,
    weightUnit: WeightUnit,
    onSave: (weightKg: Double?, sets: Int?, reps: Int?) -> Unit,
    onDismiss: () -> Unit,
) {
    // Prefill so the user can consult/edit what they last did.
    var weightText by remember(entry.id) {
        mutableStateOf(entry.lastWeightKg?.let { weightUnit.displayValue(it).roundToInt().toString() } ?: "")
    }
    var sets by remember(entry.id) { mutableIntStateOf(entry.lastSets ?: 0) }
    var reps by remember(entry.id) { mutableIntStateOf(entry.lastReps ?: 0) }

    val parsedWeight = weightText.replace(',', '.').toDoubleOrNull()
    val isValid = (parsedWeight ?: 0.0) > 0.0

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = entry.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.height(24.dp))

            // Weight hero — the value IS the display; tap it to type.
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                TextField(
                    value = weightText,
                    onValueChange = { new -> weightText = new.filter { it.isDigit() || it == '.' || it == ',' } },
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
                    text = weightUnit.displayLabel,
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(bottom = 16.dp),
                )
            }

            entry.lastTrainedDate?.let { last ->
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

            // Sets / Reps — steppers, no keyboard.
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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

            Spacer(Modifier.height(32.dp))

            Button(
                onClick = {
                    val kg = parsedWeight?.let { weightUnit.toKg(it.roundToInt().toDouble()) }
                    // 0 means "not recorded" → store as null to keep the data clean.
                    onSave(kg, sets.takeIf { it > 0 }, reps.takeIf { it > 0 })
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
