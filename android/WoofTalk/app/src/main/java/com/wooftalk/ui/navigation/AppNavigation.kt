package com.wooftalk.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.revenuecat.purchases.ui.revenuecatui.Paywall
import dagger.hilt.android.EntryPointAccessors

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
    
    // Get EntitlementManager via Hilt EntryPoint
    val context = androidx.compose.ui.platform.LocalContext.current
    val entitlementManager = remember {
        EntryPointAccessors.fromApplication(
            context,
            EntitlementManagerEntryPoint::class.java
        ).entitlementManager()
    }
    
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
                entitlementManager = entitlementManager,
                onComplete = { navController.popBackStack() },
                onNavigateBack = { navController.popBackStack() }
            )
        }
        composable(Screen.Referral.route) {
            ReferralScreen(
                entitlementManager = entitlementManager,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}

// Hilt EntryPoint to provide EntitlementManager
@dagger.hilt.InstallIn(dagger.hilt.components.SingletonComponent::class)
@dagger.hilt.EntryPoint
interface EntitlementManagerEntryPoint {
    fun entitlementManager(): com.wooftalk.EntitlementManager
}
