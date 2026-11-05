package com.zadkiel.musclecheck.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

/// Semantic accents that Material's ColorScheme has no slot for (checked state, streak flame).
data class MuscleCheckAccents(
    val success: Color,
    val streak: Color,
)

val LocalAccents = staticCompositionLocalOf {
    MuscleCheckAccents(success = SuccessLight, streak = StreakLight)
}

// Every role is set and opaque. Roles left out fall back to Material's baseline violet, which is
// how sheets, dialogs, menus and the time picker came out lavender; and a translucent
// primaryContainer made the FAB see-through. The primary family is the brand's sky ramp
// (Tailwind sky, like the iOS assets); surfaces are the neutral greys the screens already use.
// No dynamic color on purpose: the blue is the app's identity, wallpaper colors would replace it.
private val LightColors: ColorScheme = lightColorScheme(
    primary = BrandLight,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE0F2FE),
    onPrimaryContainer = Color(0xFF0C4A6E),
    inversePrimary = BrandDark,
    secondary = Color(0xFF475569),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE0F2FE),
    onSecondaryContainer = Color(0xFF0C4A6E),
    tertiary = SuccessLight,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFDCFCE7),
    onTertiaryContainer = Color(0xFF14532D),
    background = Color(0xFFF2F2F7),
    onBackground = Color(0xFF1C1C1E),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF1C1C1E),
    surfaceVariant = Color(0xFFF2F2F7),
    onSurfaceVariant = Color(0xFF636366),
    surfaceTint = BrandLight,
    inverseSurface = Color(0xFF2C2C2E),
    inverseOnSurface = Color(0xFFF2F2F7),
    outline = Color(0xFF8E8E93),
    outlineVariant = Color(0xFFD1D1D6),
    surfaceBright = Color(0xFFFFFFFF),
    surfaceDim = Color(0xFFE5E5EA),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF9F9FB),
    surfaceContainer = Color(0xFFF2F2F7),
    surfaceContainerHigh = Color(0xFFFFFFFF),
    surfaceContainerHighest = Color(0xFFE5E5EA),
)

private val DarkColors: ColorScheme = darkColorScheme(
    primary = BrandDark,
    onPrimary = Color.Black,
    primaryContainer = Color(0xFF075985),
    onPrimaryContainer = Color(0xFFE0F2FE),
    inversePrimary = BrandLight,
    secondary = Color(0xFF94A3B8),
    onSecondary = Color.Black,
    secondaryContainer = Color(0xFF0C4A6E),
    onSecondaryContainer = Color(0xFFE0F2FE),
    tertiary = SuccessDark,
    onTertiary = Color.Black,
    tertiaryContainer = Color(0xFF166534),
    onTertiaryContainer = Color(0xFFDCFCE7),
    background = Color(0xFF000000),
    onBackground = Color(0xFFF2F2F7),
    surface = Color(0xFF1C1C1E),
    onSurface = Color(0xFFF2F2F7),
    surfaceVariant = Color(0xFF2C2C2E),
    onSurfaceVariant = Color(0xFFAEAEB2),
    surfaceTint = BrandDark,
    inverseSurface = Color(0xFFE5E5EA),
    inverseOnSurface = Color(0xFF1C1C1E),
    outline = Color(0xFF8E8E93),
    outlineVariant = Color(0xFF48484A),
    surfaceBright = Color(0xFF3A3A3C),
    surfaceDim = Color(0xFF000000),
    surfaceContainerLowest = Color(0xFF000000),
    surfaceContainerLow = Color(0xFF1C1C1E),
    surfaceContainer = Color(0xFF1C1C1E),
    surfaceContainerHigh = Color(0xFF2C2C2E),
    surfaceContainerHighest = Color(0xFF3A3A3C),
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
        ) {
            // Root Surface, not decoration: it paints the scheme's background AND provides
            // LocalContentColor. MaterialTheme alone does neither, so a screen without its own
            // Scaffold (the onboarding) drew black default text over the white windowBackground
            // while its cards used the dark scheme — unreadable in dark mode.
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = colorScheme.background,
                content = content,
            )
        }
    }
}
