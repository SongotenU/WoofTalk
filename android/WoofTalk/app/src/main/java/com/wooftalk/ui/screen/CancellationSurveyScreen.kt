package com.wooftalk.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.wooftalk.EntitlementManager
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CancellationSurveyScreen(
    entitlementManager: EntitlementManager,
    onComplete: () -> Unit,
    onNavigateBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var selectedReason by remember { mutableStateOf("") }
    var feedback by remember { mutableStateOf("") }
    var isSubmitting by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }

    val reasons = listOf(
        "Too expensive",
        "Missing features I need",
        "Not using it enough",
        "Technical issues",
        "Switching to another app",
        "Temporary break",
        "Other"
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Cancellation Survey") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Text("<")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                "Why are you cancelling?",
                style = MaterialTheme.typography.titleMedium
            )

            reasons.forEach { reason ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { selectedReason = reason }
                        .padding(vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(reason, style = MaterialTheme.typography.bodyLarge)
                    if (selectedReason == reason) {
                        Text("✓", color = MaterialTheme.colorScheme.primary)
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                "Additional feedback (optional)",
                style = MaterialTheme.typography.titleMedium
            )

            TextField(
                value = feedback,
                onValueChange = { feedback = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp),
                placeholder = { Text("Tell us how we can improve...") }
            )

            if (showError) {
                Text(
                    "Failed to submit. Please try again.",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall
                )
            }

            Button(
                onClick = {
                    if (selectedReason.isNotEmpty()) {
                        isSubmitting = true
                        scope.launch {
                            try {
                                // Submit survey to Supabase via API call
                                // For now, just simulate
                                kotlinx.coroutines.delay(1000)
                                // RevenueCat doesn't have direct cancel in Android SDK
                                // User cancels through Play Store settings
                                onComplete()
                            } catch (e: Exception) {
                                showError = true
                            }
                            isSubmitting = false
                        }
                    }
                },
                enabled = selectedReason.isNotEmpty() && !isSubmitting,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = MaterialTheme.colorScheme.onError
                    )
                } else {
                    Text("Submit & Cancel Subscription")
                }
            }
        }
    }
}
