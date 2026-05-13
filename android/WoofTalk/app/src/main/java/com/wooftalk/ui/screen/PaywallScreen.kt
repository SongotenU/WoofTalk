package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.EntitlementManager

@Composable
fun PaywallScreen(
    entitlementManager: EntitlementManager,
    onDismiss: () -> Unit
) {
    val isPremium by entitlementManager.isPremium.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "WoofTalk Premium",
            style = MaterialTheme.typography.headlineLarge
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Unlock all premium features including unlimited translations, offline mode, and more.",
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = { /* TODO: Implement purchase */ },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Upgrade to Premium")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = { entitlementManager.restorePurchases() },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Restore Purchases")
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(onClick = onDismiss) {
            Text("Not Now")
        }
    }

    if (isPremium) {
        onDismiss()
    }
}
