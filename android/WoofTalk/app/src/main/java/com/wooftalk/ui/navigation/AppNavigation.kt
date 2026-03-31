package com.wooftalk.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

sealed class Screen(val route: String, val title: String) {
    object Translate : Screen("translate", "Translate")
    object History : Screen("history", "History")
    object Settings : Screen("settings", "Settings")
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
    }
}
