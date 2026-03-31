package com.wooftalk

import com.wooftalk.voice.processor.AudioFormatProcessor
import org.junit.Assert.*
import org.junit.Test

class AudioFormatProcessorTest {
    @Test
    fun `sample rate is 44100`() {
        assertEquals(44100, AudioFormatProcessor.SAMPLE_RATE)
    }

    @Test
    fun `buffer size is positive`() {
        val bufferSize = AudioFormatProcessor.getBufferSize()
        assertTrue(bufferSize > 0)
    }

    @Test
    fun `WAV header is 44 bytes`() {
        val pcmData = ByteArray(100)
        val wavData = AudioFormatProcessor().convertToWav(pcmData)
        assertEquals(144, wavData.size)
    }

    @Test
    fun `WAV header starts with RIFF`() {
        val pcmData = ByteArray(100)
        val wavData = AudioFormatProcessor().convertToWav(pcmData)
        assertEquals('R'.code.toByte(), wavData[0])
        assertEquals('I'.code.toByte(), wavData[1])
        assertEquals('F'.code.toByte(), wavData[2])
        assertEquals('F'.code.toByte(), wavData[3])
    }

    @Test
    fun `WAV header contains WAVE`() {
        val pcmData = ByteArray(100)
        val wavData = AudioFormatProcessor().convertToWav(pcmData)
        assertEquals('W'.code.toByte(), wavData[8])
        assertEquals('A'.code.toByte(), wavData[9])
        assertEquals('V'.code.toByte(), wavData[10])
        assertEquals('E'.code.toByte(), wavData[11])
    }
}
