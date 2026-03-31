package com.wooftalk.domain.model

data class TranslationResult(
    val inputText: String,
    val outputText: String,
    val direction: TranslationDirection,
    val confidence: Double,
    val qualityScore: Double?,
    val source: TranslationSource,
    val timestamp: Long = System.currentTimeMillis()
)

enum class TranslationSource {
    AI, Vocabulary, Simple
}
