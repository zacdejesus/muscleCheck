package com.zadkiel.musclecheck.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.zadkiel.musclecheck.ui.history.HistoryScreen
import com.zadkiel.musclecheck.ui.home.HomeScreen
import com.zadkiel.musclecheck.ui.onboarding.OnboardingScreen
import com.zadkiel.musclecheck.ui.pro.PaywallScreen
import com.zadkiel.musclecheck.ui.progress.ProgressPhotosScreen
import com.zadkiel.musclecheck.ui.settings.ManageCategoriesScreen
import com.zadkiel.musclecheck.ui.settings.SettingsScreen
import com.zadkiel.musclecheck.ui.stats.StatsScreen

object Routes {
    const val HOME = "home"
    const val HISTORY = "history"
    const val STATS = "stats"
    const val SETTINGS = "settings"
    const val CATEGORIES = "categories"
    const val PROGRESS = "progress"
    const val PAYWALL = "paywall"
}

@Composable
fun MuscleCheckApp(hasCompletedOnboarding: Boolean) {
    if (!hasCompletedOnboarding) {
        OnboardingScreen()
        return
    }

    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenHistory = { navController.navigate(Routes.HISTORY) },
                onOpenStats = { navController.navigate(Routes.STATS) },
                onOpenSettings = { navController.navigate(Routes.SETTINGS) },
                onOpenProgress = { navController.navigate(Routes.PROGRESS) },
            )
        }
        composable(Routes.PROGRESS) {
            ProgressPhotosScreen(
                onBack = { navController.popBackStack() },
                onUpgrade = { navController.navigate(Routes.PAYWALL) },
            )
        }
        composable(Routes.PAYWALL) {
            PaywallScreen(onClose = { navController.popBackStack() })
        }
        composable(Routes.HISTORY) {
            HistoryScreen(onBack = { navController.popBackStack() })
        }
        composable(Routes.STATS) {
            StatsScreen(onBack = { navController.popBackStack() })
        }
        composable(Routes.SETTINGS) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onOpenCategories = { navController.navigate(Routes.CATEGORIES) },
                onOpenPaywall = { navController.navigate(Routes.PAYWALL) },
            )
        }
        composable(Routes.CATEGORIES) {
            ManageCategoriesScreen(onBack = { navController.popBackStack() })
        }
    }
}
