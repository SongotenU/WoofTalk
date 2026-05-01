package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import com.wooftalk.EntitlementManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReferralScreen(
    entitlementManager: EntitlementManager,
    onNavigateBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val clipboardManager: ClipboardManager = LocalClipboardManager.current

    var referralCode by remember { mutableStateOf("") }
    var referralLink by remember { mutableStateOf("") }
    var refereeCount by remember { mutableStateOf(0) }
    var copied by remember { mutableStateOf(false) }

    // Load referral data
    LaunchedEffect(Unit) {
        scope.launch {
            // Fetch or generate referral code from Supabase
            // For now, generate a placeholder
            referralCode = "COMING_SOON"
            referralLink = "https://wooftalk.app/subscribe?ref=$referralCode"
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Refer a Friend") },
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
                "Invite friends to WoofTalk",
                style = MaterialTheme.typography.titleLarge
            )

            Text(
                "Share your referral link. When friends subscribe, you both get 1 month free.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Referral link card
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        "Your Referral Link",
                        style = MaterialTheme.typography.titleMedium
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            referralLink,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.weight(1f)
                        )
                        Button(
                            onClick = {
                                clipboardManager.setText(AnnotatedString(referralLink))
                                copied = true
                            }
                        ) {
                            Text(if (copied) "Copied!" else "Copy")
                        }
                    }

                    Text(
                        "Code: $referralCode",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Stats card
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        "Your Referrals",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        "$refereeCount friends referred",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
        }
    }
}
