package com.wooftalk

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
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
import androidx.lifecycle.lifecycleScope
import com.wooftalk.ui.navigation.Screen
import com.wooftalk.ui.screen.HistoryScreen
import com.wooftalk.ui.screen.SettingsScreen
import com.wooftalk.ui.screen.TranslationScreen
import com.wooftalk.ui.theme.WoofTalkTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var entitlementManager: EntitlementManager

    private var isInPipMode = false

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Enable PiP mode support
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            setPictureInPictureParams(
                PictureInPictureParams.Builder()
                    .setAspectRatio(android.util.Rational(16, 9))
                    .build()
            )
        }

        // Handle shortcut intents
        handleIntent(intent)

        setContent {
            WoofTalkTheme {
                WoofTalkApp()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        isInPipMode = isInPictureInPictureMode
        // Adjust UI for PiP mode - hide non-essential elements
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: android.content.Intent?) {
        intent?.getStringExtra("navigate_to")?.let { destination ->
            // Handle navigation based on shortcut or deep link
            when (destination) {
                "translate" -> {
                    // Navigate to translation tab
                }
                "history" -> {
                    // Navigate to history tab
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Check entitlements on resume to get fresh state after cross-platform purchase
        lifecycleScope.launch {
            entitlementManager.checkEntitlements()
        }
    }

    fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPictureInPictureMode(
                PictureInPictureParams.Builder()
                    .setAspectRatio(android.util.Rational(16, 9))
                    .build()
            )
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