package com.wooftalk

import com.wooftalk.domain.adapter.*
import com.wooftalk.domain.engine.*
import com.wooftalk.domain.model.TranslationDirection
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class TranslationEngineTest {
    private lateinit var engine: TranslationEngine
    private lateinit var detector: LanguageDetector
    private lateinit var router: MultiLanguageRouter

    @Before
    fun setup() {
        val adapters = mapOf(
            "dog" to DogLanguageAdapter(),
            "cat" to CatLanguageAdapter(),
            "bird" to BirdLanguageAdapter()
        )
        engine = TranslationEngine(adapters)
        detector = LanguageDetector(adapters.values.toList())
        router = MultiLanguageRouter(engine, detector)
    }

    @Test
    fun `translate hello to dog`() {
        val result = engine.translate("hello", TranslationDirection.HumanToDog)
        assertEquals("woof woof", result.outputText)
        assertEquals(1.0, result.confidence, 0.01)
    }

    @Test
    fun `translate hello to cat`() {
        val result = engine.translate("hello", TranslationDirection.HumanToCat)
        assertEquals("meow", result.outputText)
        assertEquals(1.0, result.confidence, 0.01)
    }

    @Test
    fun `translate hello to bird`() {
        val result = engine.translate("hello", TranslationDirection.HumanToBird)
        assertEquals("chirp chirp", result.outputText)
        assertEquals(1.0, result.confidence, 0.01)
    }

    @Test
    fun `translate unknown text uses simple fallback`() {
        val result = engine.translate("xyzabc", TranslationDirection.HumanToDog)
        assertTrue(result.outputText.isNotEmpty())
        assertTrue(result.confidence < 0.5)
    }

    @Test
    fun `translate multi-word sentence`() {
        val result = engine.translate("i love you", TranslationDirection.HumanToDog)
        assertEquals("woof woof woof", result.outputText)
    }

    @Test
    fun `auto-detect human text`() {
        val detected = detector.detectLanguage("hello world")
        assertEquals("human", detected)
    }

    @Test
    fun `auto-detect dog language`() {
        val detected = detector.detectLanguage("woof woof bark")
        assertEquals("Dog", detected)
    }

    @Test
    fun `auto-detect cat language`() {
        val detected = detector.detectLanguage("meow purr meow")
        assertEquals("Cat", detected)
    }

    @Test
    fun `router translates human to target language`() {
        val result = router.translateAuto("hello", "dog")
        assertEquals("hello", result.inputText)
        assertEquals("woof woof", result.outputText)
    }

    @Test
    fun `router translates animal to human`() {
        val result = router.translateAuto("woof woof", "human")
        assertEquals("hello", result.outputText)
    }

    @Test
    fun `translation result has correct direction`() {
        val result = engine.translate("hello", TranslationDirection.HumanToDog)
        assertEquals(TranslationDirection.HumanToDog, result.direction)
    }

    @Test
    fun `translation result has timestamp`() {
        val result = engine.translate("hello", TranslationDirection.HumanToDog)
        assertTrue(result.timestamp > 0)
    }

    @Test
    fun `all supported languages return non-empty output`() {
        val directions = TranslationDirection.values()
        directions.forEach { dir ->
            val result = engine.translate("hello", dir)
            assertTrue("Output empty for $dir", result.outputText.isNotEmpty())
        }
    }

    @Test
    fun `confidence score between 0 and 1`() {
        val directions = TranslationDirection.values()
        directions.forEach { dir ->
            val result = engine.translate("hello", dir)
            assertTrue("Confidence out of range for $dir", result.confidence in 0.0..1.0)
        }
    }

    @Test
    fun `exact phrase matches have confidence 1_0`() {
        val phrases = listOf("hello", "goodbye", "i love you", "food", "play")
        phrases.forEach { phrase ->
            val result = engine.translate(phrase, TranslationDirection.HumanToDog)
            assertEquals("Confidence not 1.0 for '$phrase'", 1.0, result.confidence, 0.01)
        }
    }

    @Test
    fun `empty input returns empty output`() {
        val result = engine.translate("", TranslationDirection.HumanToDog)
        // Engine should handle empty input gracefully
        assertNotNull(result)
    }

    @Test
    fun `case insensitive translation`() {
        val lowerResult = engine.translate("hello", TranslationDirection.HumanToDog)
        val upperResult = engine.translate("HELLO", TranslationDirection.HumanToDog)
        assertEquals(lowerResult.outputText, upperResult.outputText)
    }

    @Test
    fun `whitespace trimmed`() {
        val result = engine.translate("  hello  ", TranslationDirection.HumanToDog)
        assertEquals("woof woof", result.outputText)
    }

    @Test
    fun `dog to human translation`() {
        val result = engine.translate("woof woof", TranslationDirection.DogToHuman)
        assertEquals("hello", result.outputText)
    }

    @Test
    fun `cat to human translation`() {
        val result = engine.translate("meow", TranslationDirection.CatToHuman)
        assertEquals("hello", result.outputText)
    }

    @Test
    fun `bird to human translation`() {
        val result = engine.translate("chirp chirp", TranslationDirection.BirdToHuman)
        assertEquals("hello", result.outputText)
    }

    @Test
    fun `get supported languages returns all adapters`() {
        val languages = engine.getSupportedLanguages()
        assertTrue(languages.contains("dog"))
        assertTrue(languages.contains("cat"))
        assertTrue(languages.contains("bird"))
    }
}
