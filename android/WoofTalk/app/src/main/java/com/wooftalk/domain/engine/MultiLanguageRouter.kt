package com.wooftalk.domain.engine

import com.wooftalk.domain.adapter.LanguageAdapter
import com.wooftalk.domain.model.TranslationDirection
import com.wooftalk.domain.model.TranslationResult

class MultiLanguageRouter(
    private val engine: TranslationEngine,
    private val detector: LanguageDetector
) {
    fun translateAuto(text: String, targetLanguage: String): TranslationResult {
        val detectedSource = detector.detectLanguage(text)
        val direction = when {
            detectedSource == "human" -> {
                TranslationDirection.fromStrings("human", targetLanguage)
            }
            else -> {
                TranslationDirection.fromStrings(detectedSource ?: "human", "human")
            }
        } ?: TranslationDirection.HumanToDog

        return engine.translate(text, direction)
    }

    fun translateExplicit(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ): TranslationResult {
        val direction = TranslationDirection.fromStrings(sourceLanguage, targetLanguage)
            ?: throw IllegalArgumentException("Unsupported direction: $sourceLanguage -> $targetLanguage")
        return engine.translate(text, direction)
    }
}
