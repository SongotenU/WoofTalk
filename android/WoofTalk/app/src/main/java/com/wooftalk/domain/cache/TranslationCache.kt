package com.wooftalk.domain.cache

import com.wooftalk.domain.model.TranslationDirection
import com.wooftalk.domain.model.TranslationResult
import java.util.LinkedHashMap

class TranslationCache(
    private val maxSize: Int = 1000,
    private val ttlMillis: Long = 24 * 60 * 60 * 1000L
) {
    private val cache = object : LinkedHashMap<String, CacheEntry>(maxSize, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, CacheEntry>?): Boolean {
            return size > maxSize
        }
    }

    data class CacheEntry(
        val result: TranslationResult,
        val timestamp: Long = System.currentTimeMillis()
    )

    private fun generateKey(text: String, direction: TranslationDirection): String {
        val normalized = text.lowercase().trim()
        return "${normalized}_${direction.value}"
    }

    fun get(text: String, direction: TranslationDirection): TranslationResult? {
        val key = generateKey(text, direction)
        val entry = cache[key] ?: return null
        if (System.currentTimeMillis() - entry.timestamp > ttlMillis) {
            cache.remove(key)
            return null
        }
        return entry.result
    }

    fun put(text: String, direction: TranslationDirection, result: TranslationResult) {
        val key = generateKey(text, direction)
        cache[key] = CacheEntry(result)
    }

    fun clear() {
        cache.clear()
    }

    val size: Int get() = cache.size
    val hitRate: Double
        get() {
            if (cache.isEmpty()) return 0.0
            return cache.size.toDouble() / maxSize
        }
}
