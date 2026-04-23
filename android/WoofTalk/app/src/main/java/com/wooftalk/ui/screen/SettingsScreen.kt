package com.wooftalk.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

import android.content.Intent
import android.net.Uri
import com.wooftalk.EntitlementManager
import com.revenuecat.purchases.Purchases

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    cacheSize: Int,
    onCacheSizeChange: (Int) -> Unit,
    aiEnabled: Boolean,
    onAiToggle: (Boolean) -> Unit,
    darkTheme: Boolean,
    onThemeChange: (Boolean) -> Unit,
    entitlementManager: EntitlementManager,
    onNavigateToPaywall: () -> Unit,
    onRestorePurchases: () -> Unit = {},
    onManageSubscription: () -> Unit = {}
) {
    val isPremium by entitlementManager.isPremium.collectAsState()
    val isTrial by entitlementManager.isTrialActive.collectAsState()
    val isReady by entitlementManager.isReadyToAccessPaywall.collectAsState()
    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Settings") })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            Text("Translation", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("AI Translation", style = MaterialTheme.typography.bodyLarge)
                Switch(
                    checked = aiEnabled,
                    onCheckedChange = onAiToggle
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            Text("Appearance", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Dark Theme", style = MaterialTheme.typography.bodyLarge)
                Switch(
                    checked = darkTheme,
                    onCheckedChange = onThemeChange
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            Text("Cache", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            Text("Cache size: $cacheSize entries", style = MaterialTheme.typography.bodyMedium)
            Slider(
                value = cacheSize.toFloat(),
                onValueChange = { onCacheSizeChange(it.toInt()) },
                valueRange = 100f..5000f,
                steps = 48
            )

            Spacer(modifier = Modifier.height(16.dp))
            Text("Account", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = { /* Navigate to account screen */ },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Manage Account")
            }

            Spacer(modifier = Modifier.height(16.dp))
            Text("Subscription", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            // Subscription row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        if (isReady) {
                            onNavigateToPaywall()
                        }
                    }
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Subscription", style = MaterialTheme.typography.bodyLarge)
                when {
                    isPremium && !isTrial -> Text(
                        "Pro",
                        color = MaterialTheme.colorScheme.primary,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    isTrial -> Text(
                        "Trial",
                        color = MaterialTheme.colorScheme.primary,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    else -> Text(
                        "Subscribe",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }

            // Restore Purchases
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onRestorePurchases() }
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Restore Purchases", style = MaterialTheme.typography.bodyLarge)
            }

            // Manage Subscription (premium only)
            if (isPremium) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onManageSubscription() }
                        .padding(vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Manage Subscription", style = MaterialTheme.typography.bodyLarge)
                }
            }
        }
    }
}
