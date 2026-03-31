package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.sync.manager.SyncMetrics
import com.wooftalk.sync.manager.SyncStatus

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SyncStatusScreen(
    syncStatus: SyncStatus,
    syncMetrics: SyncMetrics,
    pendingCount: Int,
    onForceSync: () -> Unit
) {
    Scaffold(
        topBar = { TopAppBar(title = { Text("Sync Status") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = when (syncStatus) {
                                is SyncStatus.Synced -> Icons.Default.CheckCircle
                                is SyncStatus.Syncing -> Icons.Default.Sync
                                is SyncStatus.Error -> Icons.Default.Error
                                is SyncStatus.Offline -> Icons.Default.Error
                                else -> Icons.Default.Sync
                            },
                            contentDescription = null,
                            tint = when (syncStatus) {
                                is SyncStatus.Synced -> MaterialTheme.colorScheme.primary
                                is SyncStatus.Syncing -> MaterialTheme.colorScheme.secondary
                                else -> MaterialTheme.colorScheme.error
                            }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = syncStatus.toString(),
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Pending operations: $pendingCount", style = MaterialTheme.typography.bodyMedium)
                    Text("Total syncs: ${syncMetrics.totalSyncs}", style = MaterialTheme.typography.bodyMedium)
                    Text("Average latency: ${syncMetrics.averageLatencyMs}ms", style = MaterialTheme.typography.bodyMedium)
                    Text("Errors: ${syncMetrics.totalErrors}", style = MaterialTheme.typography.bodyMedium)
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = onForceSync,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Force Sync")
                    }
                }
            }
        }
    }
}
