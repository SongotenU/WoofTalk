package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.data.remote.model.RemoteLeaderboardEntry

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeaderboardScreen(
    entries: List<RemoteLeaderboardEntry>,
    currentUserId: String,
    onPeriodChange: (String) -> Unit,
    isLoading: Boolean
) {
    var selectedPeriod by remember { mutableStateOf("all_time") }

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Leaderboard") })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            ScrollableTabRow(
                selectedTabIndex = when (selectedPeriod) {
                    "daily" -> 0
                    "weekly" -> 1
                    "monthly" -> 2
                    else -> 3
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                listOf("daily", "weekly", "monthly", "all_time").forEach { period ->
                    Tab(
                        selected = selectedPeriod == period,
                        onClick = {
                            selectedPeriod = period
                            onPeriodChange(period)
                        },
                        text = { Text(period.replace("_", " ").capitalize()) }
                    )
                }
            }

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(entries) { entry ->
                        LeaderboardItem(
                            entry = entry,
                            isCurrentUser = entry.user?.id == currentUserId
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LeaderboardItem(
    entry: RemoteLeaderboardEntry,
    isCurrentUser: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentUser) MaterialTheme.colorScheme.primaryContainer
            else MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "#${entry.rank}",
                    style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.width(40.dp)
                )
                Column {
                    Text(entry.user?.displayName ?: "Unknown", style = MaterialTheme.typography.bodyLarge)
                    Text(entry.user?.platform ?: "", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Text("${entry.score} pts", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
        }
    }
}
