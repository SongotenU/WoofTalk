package com.wooftalk.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.revenuecat.purchases.ui.revenuecatui.Paywall

sealed class Screen(val route: String, val title: String) {
    object Translate : Screen("translate", "Translate")
    object History : Screen("history", "History")
    object Settings : Screen("settings", "Settings")
    object Paywall : Screen("paywall", "Subscription")
    object CancellationSurvey : Screen("cancellation_survey", "Cancellation Survey")
    object Referral : Screen("referral", "Refer a Friend")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    NavHost(
        navController = navController,
        startDestination = Screen.Translate.route
    ) {
        composable(Screen.Translate.route) { /* TranslationScreen */ }
        composable(Screen.History.route) { /* HistoryScreen */ }
        composable(Screen.Settings.route) { /* SettingsScreen */ }
        composable(Screen.Paywall.route) {
            Paywall(
                onDismiss = { navController.popBackStack() }
            )
        }
        composable(Screen.CancellationSurvey.route) {
            CancellationSurveyScreen(
                entitlementManager = TODO(), // Pass EntitlementManager
                onComplete = { navController.popBackStack() },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        composable(Screen.Referral.route) {
            ReferralScreen(
                entitlementManager = TODO(), // Pass EntitlementManager
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
