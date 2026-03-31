package com.wooftalk.voice.engine

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import java.util.Locale

class TextToSpeechEngine(
    private val context: Context,
    private var speed: Float = 1.0f,
    private var pitch: Float = 1.0f
) {
    private var tts: TextToSpeech? = null
    private val readyChannel = Channel<Boolean>(Channel.UNLIMITED)
    private val completionChannel = Channel<String>(Channel.UNLIMITED)
    private val errorChannel = Channel<String>(Channel.UNLIMITED)

    val isReady: Flow<Boolean> = readyChannel.receiveAsFlow()
    val onCompletion: Flow<String> = completionChannel.receiveAsFlow()
    val onError: Flow<String> = errorChannel.receiveAsFlow()

    var isInitialized = false
        private set

    init {
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.US
                tts?.setSpeechRate(speed)
                tts?.setPitch(pitch)
                setupUtteranceListener()
                isInitialized = true
                readyChannel.trySend(true)
            } else {
                errorChannel.trySend("TTS initialization failed")
            }
        }
    }

    private fun setupUtteranceListener() {
        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) {
                utteranceId?.let { completionChannel.trySend(it) }
            }
            override fun onError(utteranceId: String?) {
                utteranceId?.let { errorChannel.trySend("TTS error: $it") }
            }
        })
    }

    fun speak(text: String, utteranceId: String? = null) {
        if (!isInitialized) return
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
    }

    fun setSpeed(speed: Float) {
        this.speed = speed.coerceIn(0.1f, 3.0f)
        tts?.setSpeechRate(this.speed)
    }

    fun setPitch(pitch: Float) {
        this.pitch = pitch.coerceIn(0.1f, 2.0f)
        tts?.setPitch(this.pitch)
    }

    fun stop() {
        tts?.stop()
    }

    fun isSpeaking(): Boolean = tts?.isSpeaking ?: false

    fun destroy() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }
}
