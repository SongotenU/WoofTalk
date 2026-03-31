package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    cacheSize: Int,
    onCacheSizeChange: (Int) -> Unit,
    aiEnabled: Boolean,
    onAiToggle: (Boolean) -> Unit,
    darkTheme: Boolean,
    onThemeChange: (Boolean) -> Unit
) {
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
        }
    }
}
