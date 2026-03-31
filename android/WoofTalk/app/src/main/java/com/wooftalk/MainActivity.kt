package com.wooftalk

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.wooftalk.ui.navigation.Screen
import com.wooftalk.ui.screen.HistoryScreen
import com.wooftalk.ui.screen.SettingsScreen
import com.wooftalk.ui.screen.TranslationScreen
import com.wooftalk.ui.theme.WoofTalkTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            WoofTalkTheme {
                WoofTalkApp()
            }
        }
    }
}

@Composable
fun WoofTalkApp() {
    var selectedTab by remember { mutableIntStateOf(0) }
    val screens = listOf(Screen.Translate, Screen.History, Screen.Settings)

    Scaffold(
        bottomBar = {
            NavigationBar {
                screens.forEachIndexed { index, screen ->
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = when (screen) {
                                    Screen.Translate -> Icons.Default.Translate
                                    Screen.History -> Icons.Default.History
                                    Screen.Settings -> Icons.Default.Settings
                                },
                                contentDescription = screen.title
                            )
                        },
                        label = { Text(screen.title) },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index }
                    )
                }
            }
        }
    ) { padding ->
        when (selectedTab) {
            0 -> TranslationScreen(
                onTranslate = { _, _ -> },
                onToggleFavorite = {},
                results = emptyList(),
                isTranslating = false,
                modifier = Modifier.padding(padding)
            )
            1 -> HistoryScreen(
                translations = emptyList(),
                onDelete = {},
                onToggleFavorite = {},
                modifier = Modifier.padding(padding)
            )
            2 -> SettingsScreen(
                cacheSize = 1000,
                onCacheSizeChange = {},
                aiEnabled = false,
                onAiToggle = {},
                darkTheme = false,
                onThemeChange = {},
                modifier = Modifier.padding(padding)
            )
        }
    }
}
