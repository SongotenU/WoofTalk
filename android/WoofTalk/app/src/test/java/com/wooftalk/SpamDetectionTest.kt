package com.wooftalk

import com.wooftalk.domain.usecase.SpamDetectionService
import android.content.Context
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito.*

class SpamDetectionTest {
    private lateinit var service: SpamDetectionService
    private lateinit var mockContext: Context

    @Before
    fun setup() {
        mockContext = mock(Context::class.java)
        service = SpamDetectionService(mockContext)
    }

    @Test
    fun `normal text is not spam`() {
        val result = service.analyze("hello world", "user1")
        assertFalse(result.isSpam)
    }

    @Test
    fun `repeated characters detected as spam`() {
        val result = service.analyze("aaaaabbbbb", "user1")
        assertTrue(result.isSpam)
    }

    @Test
    fun `URL detected as spam`() {
        val result = service.analyze("check out http://spam.com", "user1")
        assertTrue(result.isSpam)
    }

    @Test
    fun `spam keywords detected`() {
        val result = service.analyze("buy cheap stuff", "user1")
        assertTrue(result.isSpam)
    }

    @Test
    fun `long text increases spam score`() {
        val longText = "a".repeat(501)
        val result = service.analyze(longText, "user1")
        assertTrue(result.isSpam)
    }

    @Test
    fun `high word repetition detected`() {
        val result = service.analyze("word word word word word", "user1")
        assertTrue(result.isSpam)
    }

    @Test
    fun `rapid submissions detected`() {
        val userId = "spammer"
        repeat(6) {
            service.analyze("normal text $it", userId)
        }
        val result = service.analyze("another one", userId)
        assertTrue(result.isSpam)
    }

    @Test
    fun `spam confidence between 0 and 1`() {
        val result = service.analyze("hello world", "user1")
        assertTrue(result.confidence in 0.0..1.0)
    }

    @Test
    fun `clear old data works`() {
        val userId = "user1"
        repeat(10) { service.analyze("text $it", userId) }
        service.clearOldData()
        val result = service.analyze("new text", userId)
        assertFalse(result.reasons.any { it.contains("Too many submissions") })
    }
}
