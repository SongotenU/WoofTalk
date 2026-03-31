package com.wooftalk.domain.engine

import com.wooftalk.domain.adapter.LanguageAdapter

class LanguageDetector(
    private val adapters: List<LanguageAdapter>
) {
    fun detectLanguage(text: String): String? {
        val normalized = text.lowercase().trim()
        var bestMatch: Pair<String, Double>? = null

        for (adapter in adapters) {
            val score = adapter.simpleSounds.count { normalized.contains(it) }.toDouble() / adapter.simpleSounds.size
            if (score > 0.0 && (bestMatch == null || score > bestMatch.second)) {
                bestMatch = adapter.languageName to score
            }
        }

        return if (bestMatch?.second ?: 0.0 >= 0.3) bestMatch?.first else "human"
    }
}
