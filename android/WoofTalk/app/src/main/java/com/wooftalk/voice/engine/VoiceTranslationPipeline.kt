package com.wooftalk.voice.engine

import com.wooftalk.domain.engine.MultiLanguageRouter
import com.wooftalk.domain.model.TranslationResult
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class VoiceTranslationPipeline(
    private val recognitionEngine: SpeechRecognitionEngine,
    private val ttsEngine: TextToSpeechEngine,
    private val translationRouter: MultiLanguageRouter
) {
    private val pipelineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var startTime: Long = 0

    private val _pipelineStatus = MutableStateFlow<PipelineStatus>(PipelineStatus.Idle)
    val pipelineStatus: StateFlow<PipelineStatus> = _pipelineStatus.asStateFlow()

    private val _results = MutableSharedFlow<TranslationResult>()
    val results: SharedFlow<TranslationResult> = _results.asSharedFlow()

    fun start(targetLanguage: String) {
        pipelineScope.launch {
            _pipelineStatus.value = PipelineStatus.Listening
            startTime = System.currentTimeMillis()

            recognitionEngine.finalResults.collect { text ->
                _pipelineStatus.value = PipelineStatus.Translating
                try {
                    val result = translationRouter.translateAuto(text, targetLanguage)
                    val translationTime = System.currentTimeMillis() - startTime
                    _pipelineStatus.value = PipelineStatus.Speaking(translationTime)

                    ttsEngine.speak(result.outputText, utteranceId = result.inputText)
                    _results.emit(result)
                    _pipelineStatus.value = PipelineStatus.Idle
                } catch (e: Exception) {
                    _pipelineStatus.value = PipelineStatus.Error(e.message ?: "Translation failed")
                }
            }
        }
        recognitionEngine.startListening()
    }

    fun stop() {
        recognitionEngine.stopListening()
        ttsEngine.stop()
        pipelineScope.cancel()
        _pipelineStatus.value = PipelineStatus.Idle
    }

    fun cancel() {
        recognitionEngine.cancel()
        ttsEngine.stop()
        _pipelineStatus.value = PipelineStatus.Idle
    }

    fun destroy() {
        stop()
        recognitionEngine.destroy()
        ttsEngine.destroy()
    }
}

sealed class PipelineStatus {
    object Idle : PipelineStatus()
    object Listening : PipelineStatus()
    object Translating : PipelineStatus()
    data class Speaking(val translationLatencyMs: Long) : PipelineStatus()
    data class Error(val message: String) : PipelineStatus()
}
