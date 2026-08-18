package com.zadkiel.musclecheck.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.CustomCategory
import com.zadkiel.musclecheck.domain.model.MetricType
import com.zadkiel.musclecheck.ui.home.MetricDropdown
import com.zadkiel.musclecheck.ui.icons.AppIcons
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ManageCategoriesViewModel @Inject constructor(
    private val repository: MuscleRepository,
) : ViewModel() {

    val categories: StateFlow<List<CustomCategory>> =
        repository.customCategories.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val error = MutableStateFlow<String?>(null)

    fun add(name: String, icon: String, defaultMetric: MetricType, onSuccess: () -> Unit) {
        viewModelScope.launch {
            try {
                repository.addCustomCategory(name, icon, defaultMetric)
                error.value = null
                onSuccess()
            } catch (e: Exception) {
                error.value = repository.errorMessage(e)
            }
        }
    }

    fun delete(category: CustomCategory) {
        viewModelScope.launch { repository.deleteCustomCategory(category.id) }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManageCategoriesScreen(
    onBack: () -> Unit,
    viewModel: ManageCategoriesViewModel = hiltViewModel(),
) {
    val categories by viewModel.categories.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    var name by remember { mutableStateOf("") }
    var selectedIcon by remember { mutableStateOf("star.fill") }
    // What entries in this category log by default — supersedes the old
    // "tracks weight" boolean now that each exercise carries its own metric.
    var defaultMetric by remember { mutableStateOf(MetricType.NONE) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_custom_categories)) },
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
            // New category form
            SettingsSection(title = stringResource(R.string.custom_category_section_new)) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        placeholder = { Text(stringResource(R.string.custom_category_name_placeholder)) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )

                    LazyVerticalGrid(
                        columns = GridCells.Fixed(6),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.height(140.dp),
                    ) {
                        items(ActivityCategory.availableIcons) { icon ->
                            val isSelected = icon == selectedIcon
                            androidx.compose.foundation.layout.Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .background(
                                        if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                        else MaterialTheme.colorScheme.surfaceVariant,
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

                    Text(
                        text = stringResource(R.string.custom_category_default_metric),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    MetricDropdown(metric = defaultMetric, onMetricChange = { defaultMetric = it })

                    error?.let { message ->
                        Text(
                            text = message,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.error,
                        )
                    }

                    Button(
                        onClick = {
                            viewModel.add(name, selectedIcon, defaultMetric) {
                                name = ""
                                defaultMetric = MetricType.NONE
                                selectedIcon = "star.fill"
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(stringResource(R.string.custom_category_add))
                    }
                }
            }

            // Existing categories
            SettingsSection(title = stringResource(R.string.custom_category_section_yours)) {
                if (categories.isEmpty()) {
                    Text(
                        text = stringResource(R.string.custom_category_empty),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(16.dp),
                    )
                } else {
                    categories.forEach { category ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(
                                imageVector = AppIcons.forKey(category.icon),
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(22.dp),
                            )
                            Spacer(Modifier.width(12.dp))
                            Text(category.name, modifier = Modifier.weight(1f))
                            IconButton(onClick = { viewModel.delete(category) }) {
                                Icon(
                                    imageVector = Icons.Filled.Delete,
                                    contentDescription = stringResource(R.string.delete),
                                    tint = MaterialTheme.colorScheme.error,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
