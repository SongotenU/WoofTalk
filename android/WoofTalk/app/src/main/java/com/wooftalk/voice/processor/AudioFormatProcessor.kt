package com.wooftalk.voice.processor

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder

class AudioFormatProcessor {
    companion object {
        const val SAMPLE_RATE = 44100
        const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        const val BUFFER_SIZE_MULTIPLIER = 2

        fun getBufferSize(): Int {
            val minBufferSize = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT
            )
            return minBufferSize * BUFFER_SIZE_MULTIPLIER
        }

        fun createAudioRecord(): AudioRecord {
            return AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                getBufferSize()
            )
        }
    }

    fun convertToWav(pcmData: ByteArray): ByteArray {
        val wavHeader = createWavHeader(pcmData.size)
        return wavHeader + pcmData
    }

    private fun createWavHeader(dataSize: Int): ByteArray {
        val totalSize = 36 + dataSize
        return ByteArray(44).apply {
            this[0] = 'R'.code.toByte()
            this[1] = 'I'.code.toByte()
            this[2] = 'F'.code.toByte()
            this[3] = 'F'.code.toByte()
            this[4] = (totalSize and 0xff).toByte()
            this[5] = ((totalSize shr 8) and 0xff).toByte()
            this[6] = ((totalSize shr 16) and 0xff).toByte()
            this[7] = ((totalSize shr 24) and 0xff).toByte()
            this[8] = 'W'.code.toByte()
            this[9] = 'A'.code.toByte()
            this[10] = 'V'.code.toByte()
            this[11] = 'E'.code.toByte()
            this[12] = 'f'.code.toByte()
            this[13] = 'm'.code.toByte()
            this[14] = 't'.code.toByte()
            this[15] = ' '.code.toByte()
            this[16] = 16
            this[20] = 1
            this[22] = 1
            this[24] = (SAMPLE_RATE and 0xff).toByte()
            this[25] = ((SAMPLE_RATE shr 8) and 0xff).toByte()
            this[26] = ((SAMPLE_RATE shr 16) and 0xff).toByte()
            this[27] = ((SAMPLE_RATE shr 24) and 0xff).toByte()
            this[34] = 16
            this[36] = 'd'.code.toByte()
            this[37] = 'a'.code.toByte()
            this[38] = 't'.code.toByte()
            this[39] = 'a'.code.toByte()
            this[40] = (dataSize and 0xff).toByte()
            this[41] = ((dataSize shr 8) and 0xff).toByte()
            this[42] = ((dataSize shr 16) and 0xff).toByte()
            this[43] = ((dataSize shr 24) and 0xff).toByte()
        }
    }
}
