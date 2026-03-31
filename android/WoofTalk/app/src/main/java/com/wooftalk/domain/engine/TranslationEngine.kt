package com.wooftalk.domain.engine

import com.wooftalk.domain.adapter.LanguageAdapter
import com.wooftalk.domain.model.TranslationDirection
import com.wooftalk.domain.model.TranslationResult
import com.wooftalk.domain.model.TranslationSource

class TranslationEngine(
    private val adapters: Map<String, LanguageAdapter>
) {
    fun translate(
        text: String,
        direction: TranslationDirection
    ): TranslationResult {
        val (sourceLang, targetLang) = direction.value.split("_to_")
        val adapter = adapters[targetLang.lowercase()]
            ?: throw IllegalArgumentException("No adapter for language: $targetLang")

        val (outputText, confidence) = when (direction) {
            TranslationDirection.HumanToDog,
            TranslationDirection.HumanToCat,
            TranslationDirection.HumanToBird -> adapter.translateToAnimal(text)

            TranslationDirection.DogToHuman,
            TranslationDirection.CatToHuman,
            TranslationDirection.BirdToHuman -> adapter.translateToHuman(text)
        }

        return TranslationResult(
            inputText = text,
            outputText = outputText,
            direction = direction,
            confidence = confidence,
            qualityScore = null,
            source = if (confidence >= 0.5) TranslationSource.Vocabulary else TranslationSource.Simple
        )
    }

    fun getSupportedLanguages(): List<String> = adapters.keys.toList()
}
