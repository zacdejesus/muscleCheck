package com.zadkiel.musclecheck.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.ui.icons.AppIcons
import com.zadkiel.musclecheck.ui.theme.LocalAccents
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val repository: MuscleRepository,
) : ViewModel() {

    /** Seeds the picked categories' presets and completes onboarding. */
    fun complete(selected: Set<ActivityCategory>) {
        viewModelScope.launch { repository.completeOnboarding(selected.toList()) }
    }

    /** Skip keeps the classic default: the gym seed. */
    fun skip() {
        viewModelScope.launch { repository.completeOnboarding(listOf(ActivityCategory.GYM)) }
    }
}

/** Two screens, zero permissions: show the mental model, personalize the list, get out. */
@Composable
fun OnboardingScreen(viewModel: OnboardingViewModel = hiltViewModel()) {
    var step by remember { mutableStateOf(0) }

    AnimatedContent(targetState = step, label = "onboarding") { current ->
        when (current) {
            0 -> WelcomeStep(onContinue = { step = 1 })
            else -> CategoryPickerStep(
                onContinue = { selected -> viewModel.complete(selected) },
                onSkip = { viewModel.skip() },
            )
        }
    }
}

@Composable
private fun WelcomeStep(onContinue: () -> Unit) {
    val accents = LocalAccents.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))

        // Demo checklist: static preview of the core loop.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            DemoRow(stringResource(R.string.group_chest), checked = true, success = accents.success)
            DemoRow(stringResource(R.string.group_back), checked = true, success = accents.success)
            DemoRow(stringResource(R.string.group_legs), checked = false, success = accents.success)
        }

        Spacer(Modifier.height(40.dp))
        Text(
            text = stringResource(R.string.onboarding_welcome_title),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(12.dp))
        Text(
            text = stringResource(R.string.onboarding_welcome_body),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.weight(2f))

        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.onboarding_welcome_cta))
        }
    }
}

@Composable
private fun DemoRow(name: String, checked: Boolean, success: androidx.compose.ui.graphics.Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), RoundedCornerShape(8.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = AppIcons.forKey("figure.strengthtraining.traditional"),
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(18.dp),
            )
        }
        Spacer(Modifier.width(12.dp))
        Text(name, modifier = Modifier.weight(1f))
        Icon(
            imageVector = if (checked) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
            contentDescription = null,
            tint = if (checked) success else MaterialTheme.colorScheme.outline,
        )
    }
}

@Composable
private fun CategoryPickerStep(
    onContinue: (Set<ActivityCategory>) -> Unit,
    onSkip: () -> Unit,
) {
    var selected by remember { mutableStateOf(setOf(ActivityCategory.GYM)) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
    ) {
        Spacer(Modifier.height(24.dp))
        Text(
            text = stringResource(R.string.onboarding_picker_title),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.onboarding_picker_subtitle),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(24.dp))

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ActivityCategory.entries.filter { it != ActivityCategory.CUSTOM }.forEach { category ->
                val isSelected = category in selected
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                            else MaterialTheme.colorScheme.surface,
                            RoundedCornerShape(12.dp),
                        )
                        .clickable {
                            selected = if (isSelected) selected - category else selected + category
                        }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        imageVector = AppIcons.forKey(category.defaultIcon),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(22.dp),
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(stringResource(category.displayNameRes), modifier = Modifier.weight(1f))
                    Icon(
                        imageVector = if (isSelected) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
                        contentDescription = null,
                        tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        Button(
            onClick = { onContinue(selected) },
            enabled = selected.isNotEmpty(),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.onboarding_picker_cta))
        }
        TextButton(onClick = onSkip, modifier = Modifier.fillMaxWidth()) {
            Text(stringResource(R.string.onboarding_skip))
        }
    }
}
