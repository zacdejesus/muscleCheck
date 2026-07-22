package com.zadkiel.musclecheck.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/// Semantic accents that Material's ColorScheme has no slot for (checked state, streak flame).
data class MuscleCheckAccents(
    val success: Color,
    val streak: Color,
)

val LocalAccents = staticCompositionLocalOf {
    MuscleCheckAccents(success = SuccessLight, streak = StreakLight)
}

private val LightColors: ColorScheme = lightColorScheme(
    primary = BrandLight,
    onPrimary = Color.White,
    primaryContainer = BrandLight.copy(alpha = 0.12f),
    onPrimaryContainer = BrandLight,
    secondary = BrandLight,
    surface = Color(0xFFFFFFFF),
    background = Color(0xFFF2F2F7),
    surfaceVariant = Color(0xFFF2F2F7),
)

private val DarkColors: ColorScheme = darkColorScheme(
    primary = BrandDark,
    onPrimary = Color.Black,
    primaryContainer = BrandDark.copy(alpha = 0.16f),
    onPrimaryContainer = BrandDark,
    secondary = BrandDark,
    surface = Color(0xFF1C1C1E),
    background = Color(0xFF000000),
    surfaceVariant = Color(0xFF2C2C2E),
)

@Composable
fun MuscleCheckTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColors else LightColors
    val accents = if (darkTheme) {
        MuscleCheckAccents(success = SuccessDark, streak = StreakDark)
    } else {
        MuscleCheckAccents(success = SuccessLight, streak = StreakLight)
    }
    androidx.compose.runtime.CompositionLocalProvider(LocalAccents provides accents) {
        MaterialTheme(
            colorScheme = colorScheme,
            content = content,
        )
    }
}
