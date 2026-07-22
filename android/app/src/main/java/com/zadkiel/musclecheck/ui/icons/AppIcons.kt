package com.zadkiel.musclecheck.ui.icons

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsBike
import androidx.compose.material.icons.automirrored.filled.DirectionsRun
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Pool
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.SportsMartialArts
import androidx.compose.material.icons.filled.SportsMma
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Entries store the iOS SF Symbol name as a stable icon key (cross-platform data compat);
 * this maps each key to the closest Material icon. Unknown keys fall back to a star.
 */
object AppIcons {

    fun forKey(key: String): ImageVector = when (key) {
        "figure.strengthtraining.traditional", "dumbbell.fill" -> Icons.Filled.FitnessCenter
        "figure.yoga" -> Icons.Filled.SelfImprovement
        "figure.pilates" -> Icons.Filled.SportsGymnastics
        "figure.run" -> Icons.AutoMirrored.Filled.DirectionsRun
        "figure.walk" -> Icons.AutoMirrored.Filled.DirectionsWalk
        "figure.outdoor.cycle" -> Icons.AutoMirrored.Filled.DirectionsBike
        "figure.pool.swim" -> Icons.Filled.Pool
        "figure.highintensity.intervaltraining" -> Icons.Filled.SportsGymnastics
        "figure.core.training" -> Icons.Filled.SportsMartialArts
        "figure.flexibility" -> Icons.Filled.SelfImprovement
        "figure.cooldown" -> Icons.Filled.Spa
        "figure.dance" -> Icons.Filled.MusicNote
        "figure.martial.arts" -> Icons.Filled.SportsMartialArts
        "figure.boxing" -> Icons.Filled.SportsMma
        "heart.fill" -> Icons.Filled.Favorite
        "flame.fill" -> Icons.Filled.LocalFireDepartment
        else -> Icons.Filled.Star
    }
}
