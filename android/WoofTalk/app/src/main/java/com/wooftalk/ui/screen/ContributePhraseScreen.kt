package com.wooftalk.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.wooftalk.data.local.entity.CommunityPhraseEntity
import com.wooftalk.domain.usecase.SpamDetectionService

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContributePhraseScreen(
    userId: String,
    onSubmit: (CommunityPhraseEntity) -> Unit,
    onNavigateBack: () -> Unit
) {
    var phraseText by remember { mutableStateOf("") }
    var selectedLanguage by remember { mutableStateOf("dog") }
    var isSubmitting by remember { mutableStateOf(false) }
    var validationResult by remember { mutableStateOf<ValidationResult?>(null) }

    val spamDetector = remember { SpamDetectionService(android.content.Context) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Contribute Phrase") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Text("←")
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
        ) {
            OutlinedTextField(
                value = phraseText,
                onValueChange = {
                    phraseText = it
                    validationResult = validateInput(it, userId, spamDetector)
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Enter phrase") },
                placeholder = { Text("e.g., 'woof woof' means 'hello'" },
                minLines = 3,
                maxLines = 5,
                isError = validationResult?.isValid == false
            )

            validationResult?.let { result ->
                if (!result.isValid) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Warning, contentDescription = null, tint = MaterialTheme.colorScheme.error)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(result.errorMessage ?: "", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text("Language", style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("dog", "cat", "bird").forEach { lang ->
                    FilterChip(
                        selected = selectedLanguage == lang,
                        onClick = { selectedLanguage = lang },
                        label = { Text(lang.capitalize()) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    isSubmitting = true
                    val phrase = CommunityPhraseEntity(
                        phraseText = phraseText.trim(),
                        language = selectedLanguage,
                        submittedBy = userId,
                        approvalStatus = "pending"
                    )
                    onSubmit(phrase)
                    isSubmitting = false
                    onNavigateBack()
                },
                enabled = validationResult?.isValid == true && !isSubmitting,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Submit Phrase")
                }
            }
        }
    }
}

data class ValidationResult(val isValid: Boolean, val errorMessage: String? = null)

private fun validateInput(text: String, userId: String, spamDetector: SpamDetectionService): ValidationResult {
    if (text.isBlank()) return ValidationResult(false, "Phrase cannot be empty")
    if (text.length > 500) return ValidationResult(false, "Phrase must be 500 characters or less")
    val spamResult = spamDetector.analyze(text, userId)
    if (spamResult.isSpam) return ValidationResult(false, "Phrase may contain spam: ${spamResult.reasons.firstOrNull()}")
    return ValidationResult(true)
}
