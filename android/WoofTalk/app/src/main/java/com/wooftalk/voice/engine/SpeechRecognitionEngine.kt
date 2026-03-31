package com.wooftalk.voice.engine

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow

class SpeechRecognitionEngine(private val context: Context) {
    private var speechRecognizer: SpeechRecognizer? = null
    private val partialResultsChannel = Channel<String>(Channel.UNLIMITED)
    private val finalResultChannel = Channel<String>(Channel.UNLIMITED)
    private val errorChannel = Channel<RecognitionError>(Channel.UNLIMITED)

    val partialResults: Flow<String> = partialResultsChannel.receiveAsFlow()
    val finalResults: Flow<String> = finalResultChannel.receiveAsFlow()
    val errors: Flow<RecognitionError> = errorChannel.receiveAsFlow()

    var isListening = false
        private set

    init {
        if (SpeechRecognizer.isRecognitionAvailable(context)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            setupListener()
        }
    }

    private fun setupListener() {
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) { isListening = true }
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() { isListening = false }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val confidence = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
                val text = matches?.firstOrNull() ?: ""
                finalResultChannel.trySend(text)
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { partialResultsChannel.trySend(it) }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}

            override fun onError(error: Int) {
                isListening = false
                errorChannel.trySend(RecognitionError.fromCode(error))
            }
        })
    }

    fun startListening(language: String = "en-US") {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        speechRecognizer?.startListening(intent)
    }

    fun stopListening() {
        speechRecognizer?.stopListening()
        isListening = false
    }

    fun cancel() {
        speechRecognizer?.cancel()
        isListening = false
    }

    fun destroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
    }
}

data class RecognitionError(val code: Int, val message: String) {
    companion object {
        fun fromCode(code: Int) = when (code) {
            SpeechRecognizer.ERROR_AUDIO -> RecognitionError(code, "Audio recording error")
            SpeechRecognizer.ERROR_CLIENT -> RecognitionError(code, "Client error")
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> RecognitionError(code, "Insufficient permissions")
            SpeechRecognizer.ERROR_NETWORK -> RecognitionError(code, "Network error")
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> RecognitionError(code, "Network timeout")
            SpeechRecognizer.ERROR_NO_MATCH -> RecognitionError(code, "No speech match")
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> RecognitionError(code, "Recognition service busy")
            SpeechRecognizer.ERROR_SERVER -> RecognitionError(code, "Server error")
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> RecognitionError(code, "No speech input")
            else -> RecognitionError(code, "Unknown error: $code")
        }
    }
}
