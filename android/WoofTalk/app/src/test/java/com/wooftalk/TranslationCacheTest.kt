package com.wooftalk

import com.wooftalk.domain.cache.TranslationCache
import com.wooftalk.domain.model.*
import org.junit.Assert.*
import org.junit.Test

class TranslationCacheTest {
    @Test
    fun `cache miss returns null`() {
        val cache = TranslationCache()
        val result = cache.get("hello", TranslationDirection.HumanToDog)
        assertNull(result)
    }

    @Test
    fun `cache hit returns stored result`() {
        val cache = TranslationCache()
        val expected = TranslationResult("hello", "woof", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary)
        cache.put("hello", TranslationDirection.HumanToDog, expected)
        val actual = cache.get("hello", TranslationDirection.HumanToDog)
        assertEquals(expected, actual)
    }

    @Test
    fun `cache evicts oldest entry when full`() {
        val cache = TranslationCache(maxSize = 2)
        cache.put("a", TranslationDirection.HumanToDog, TranslationResult("a", "a", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        cache.put("b", TranslationDirection.HumanToDog, TranslationResult("b", "b", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        cache.put("c", TranslationDirection.HumanToDog, TranslationResult("c", "c", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        assertNull(cache.get("a", TranslationDirection.HumanToDog))
        assertNotNull(cache.get("b", TranslationDirection.HumanToDog))
        assertNotNull(cache.get("c", TranslationDirection.HumanToDog))
    }

    @Test
    fun `expired entry returns null`() {
        val cache = TranslationCache(ttlMillis = 1)
        cache.put("hello", TranslationDirection.HumanToDog, TranslationResult("hello", "woof", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        Thread.sleep(10)
        assertNull(cache.get("hello", TranslationDirection.HumanToDog))
    }

    @Test
    fun `clear removes all entries`() {
        val cache = TranslationCache()
        cache.put("a", TranslationDirection.HumanToDog, TranslationResult("a", "a", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        cache.put("b", TranslationDirection.HumanToDog, TranslationResult("b", "b", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        cache.clear()
        assertNull(cache.get("a", TranslationDirection.HumanToDog))
        assertNull(cache.get("b", TranslationDirection.HumanToDog))
    }

    @Test
    fun `size tracks entry count`() {
        val cache = TranslationCache()
        assertEquals(0, cache.size)
        cache.put("a", TranslationDirection.HumanToDog, TranslationResult("a", "a", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        assertEquals(1, cache.size)
        cache.put("b", TranslationDirection.HumanToDog, TranslationResult("b", "b", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary))
        assertEquals(2, cache.size)
    }

    @Test
    fun `case insensitive key generation`() {
        val cache = TranslationCache()
        val result = TranslationResult("hello", "woof", TranslationDirection.HumanToDog, 1.0, null, TranslationSource.Vocabulary)
        cache.put("Hello", TranslationDirection.HumanToDog, result)
        val cached = cache.get("HELLO", TranslationDirection.HumanToDog)
        assertNotNull(cached)
        assertEquals(result, cached)
    }
}
