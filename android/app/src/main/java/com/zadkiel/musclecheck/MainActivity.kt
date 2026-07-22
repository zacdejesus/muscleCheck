package com.zadkiel.musclecheck

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.ui.navigation.MuscleCheckApp
import com.zadkiel.musclecheck.ui.theme.MuscleCheckTheme
import dagger.hilt.android.AndroidEntryPoint
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    prefs: UserPreferencesRepository,
) : ViewModel() {
    val appTheme: Flow<Int> = prefs.appTheme
    /** Null until DataStore loads, so we don't flash the wrong first screen. */
    val hasCompletedOnboarding: Flow<Boolean?> = prefs.hasCompletedOnboarding.map { it }
}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val viewModel: MainViewModel = hiltViewModel()
            val theme by viewModel.appTheme.collectAsStateWithLifecycle(initialValue = 0)
            val hasOnboarded by viewModel.hasCompletedOnboarding.collectAsStateWithLifecycle(initialValue = null)
            val darkTheme = when (theme) {
                1 -> false
                2 -> true
                else -> isSystemInDarkTheme()
            }
            MuscleCheckTheme(darkTheme = darkTheme) {
                hasOnboarded?.let { onboarded ->
                    MuscleCheckApp(hasCompletedOnboarding = onboarded)
                }
            }
        }
    }
}
