package com.wooftalk.ui.screen

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ThumbDown
import androidx.compose.material.icons.filled.ThumbUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.data.local.entity.CommunityPhraseEntity

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommunityPhraseScreen(
    phrases: List<CommunityPhraseEntity>,
    onSearch: (String) -> Unit,
    onLanguageFilter: (String?) -> Unit,
    onUpvote: (CommunityPhraseEntity) -> Unit,
    onDownvote: (CommunityPhraseEntity) -> Unit,
    isLoading: Boolean
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedLanguage by remember { mutableStateOf<String?>(null) }
    var selectedPhrase by remember { mutableStateOf<CommunityPhraseEntity?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Community Phrases") },
                actions = {
                    FilterChip(
                        selected = selectedLanguage != null,
                        onClick = {
                            selectedLanguage = when (selectedLanguage) {
                                null -> "dog"
                                "dog" -> "cat"
                                "cat" -> "bird"
                                else -> null
                            }
                            onLanguageFilter(selectedLanguage)
                        },
                        label = { Text(selectedLanguage?.capitalize() ?: "All") }
                    )
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = {
                    searchQuery = it
                    onSearch(it)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                placeholder = { Text("Search phrases...") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                singleLine = true
            )

            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(phrases) { phrase ->
                        PhraseCard(
                            phrase = phrase,
                            onClick = { selectedPhrase = phrase },
                            onUpvote = { onUpvote(phrase) },
                            onDownvote = { onDownvote(phrase) }
                        )
                    }
                }
            }
        }
    }

    selectedPhrase?.let { phrase ->
        PhraseDetailBottomSheet(
            phrase = phrase,
            onDismiss = { selectedPhrase = null }
        )
    }
}

@Composable
private fun PhraseCard(
    phrase: CommunityPhraseEntity,
    onClick: () -> Unit,
    onUpvote: () -> Unit,
    onDownvote: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = phrase.phraseText,
                style = MaterialTheme.typography.bodyLarge
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = phrase.language.capitalize(),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    IconButton(onClick = onUpvote) {
                        Icon(Icons.Default.ThumbUp, contentDescription = "Upvote")
                        Text(phrase.upvotes.toString())
                    }
                    IconButton(onClick = onDownvote) {
                        Icon(Icons.Default.ThumbDown, contentDescription = "Downvote")
                        Text(phrase.downvotes.toString())
                    }
                }
            }
        }
    }
}

@Composable
private fun PhraseDetailBottomSheet(
    phrase: CommunityPhraseEntity,
    onDismiss: () -> Unit
) {
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(phrase.phraseText, style = MaterialTheme.typography.headlineSmall)
            Spacer(modifier = Modifier.height(8.dp))
            Text("Language: ${phrase.language.capitalize()}", style = MaterialTheme.typography.bodyMedium)
            Text("Upvotes: ${phrase.upvotes}", style = MaterialTheme.typography.bodyMedium)
            Text("Downvotes: ${phrase.downvotes}", style = MaterialTheme.typography.bodyMedium)
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text("Close")
            }
        }
    }
}
