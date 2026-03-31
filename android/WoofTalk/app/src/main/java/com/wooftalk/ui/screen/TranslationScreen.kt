package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.domain.model.TranslationDirection
import com.wooftalk.domain.model.TranslationResult
import com.wooftalk.domain.model.TranslationSource

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TranslationScreen(
    onTranslate: (String, TranslationDirection) -> Unit,
    onToggleFavorite: (String) -> Unit,
    results: List<TranslationResult>,
    isTranslating: Boolean
) {
    var inputText by remember { mutableStateOf("") }
    var selectedLanguage by remember { mutableStateOf("Dog") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("WoofTalk") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = { inputText = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Enter text to translate") },
                minLines = 3,
                maxLines = 5
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                LanguageSelector(
                    selected = selectedLanguage,
                    onSelected = { selectedLanguage = it }
                )

                Button(
                    onClick = {
                        if (inputText.isNotBlank()) {
                            val direction = when (selectedLanguage) {
                                "Dog" -> TranslationDirection.HumanToDog
                                "Cat" -> TranslationDirection.HumanToCat
                                "Bird" -> TranslationDirection.HumanToBird
                                else -> TranslationDirection.HumanToDog
                            }
                            onTranslate(inputText, direction)
                        }
                    },
                    enabled = inputText.isNotBlank() && !isTranslating,
                    modifier = Modifier
                ) {
                    Icon(Icons.Default.Translate, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(if (isTranslating) "Translating..." else "Translate")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Recent Translations",
                style = MaterialTheme.typography.titleMedium
            )

            Spacer(modifier = Modifier.height(8.dp))

            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(results) { result ->
                    TranslationCard(result, onToggleFavorite = { onToggleFavorite(result.inputText) })
                }
            }
        }
    }
}

@Composable
private fun LanguageSelector(
    selected: String,
    onSelected: (String) -> Unit
) {
    val languages = listOf("Dog", "Cat", "Bird")
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        languages.forEach { lang ->
            FilterChip(
                selected = selected == lang,
                onClick = { onSelected(lang) },
                label = { Text(lang) }
            )
        }
    }
}

@Composable
private fun TranslationCard(
    result: TranslationResult,
    onToggleFavorite: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = result.inputText,
                    style = MaterialTheme.typography.bodyMedium
                )
                IconButton(onClick = onToggleFavorite) {
                    Icon(
                        imageVector = if (result.qualityScore != null) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (result.qualityScore != null) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = result.outputText,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Confidence: ${(result.confidence * 100).toInt()}%",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "Source: ${result.source}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
