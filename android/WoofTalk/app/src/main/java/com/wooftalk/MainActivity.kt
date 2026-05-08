package com.wooftalk

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.wooftalk.ui.navigation.AppNavigation
import com.wooftalk.ui.theme.WoofTalkTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var entitlementManager: EntitlementManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            WoofTalkTheme {
                AppNavigation(
                    entitlementManager = entitlementManager
                )
            }
        }
    }
}
