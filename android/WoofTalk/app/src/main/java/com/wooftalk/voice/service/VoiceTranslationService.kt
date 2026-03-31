package com.wooftalk.voice.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.wooftalk.R
import com.wooftalk.domain.engine.MultiLanguageRouter
import com.wooftalk.domain.model.TranslationDirection
import com.wooftalk.domain.model.TranslationResult
import com.wooftalk.voice.engine.SpeechRecognitionEngine
import com.wooftalk.voice.engine.TextToSpeechEngine
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class VoiceTranslationService : Service() {
    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var recognitionEngine: SpeechRecognitionEngine? = null
    private var ttsEngine: TextToSpeechEngine? = null
    private var translationRouter: MultiLanguageRouter? = null

    private val _translationResults = MutableSharedFlow<TranslationResult>()
    val translationResults: SharedFlow<TranslationResult> = _translationResults

    private val _recognitionStatus = MutableStateFlow(RecognitionStatus.IDLE)
    val recognitionStatus: StateFlow<RecognitionStatus> = _recognitionStatus.asStateFlow()

    var isRunning = false
        private set

    var targetLanguage: String = "Dog"

    inner class LocalBinder : Binder() {
        fun getService(): VoiceTranslationService = this@VoiceTranslationService
    }

    override fun onCreate() {
        super.onCreate()
        recognitionEngine = SpeechRecognitionEngine(this)
        ttsEngine = TextToSpeechEngine(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForegroundService()
            ACTION_STOP -> stopService()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onDestroy() {
        super.onDestroy()
        recognitionEngine?.destroy()
        ttsEngine?.destroy()
        serviceScope.cancel()
    }

    private fun startForegroundService() {
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true
        setupRecognitionFlow()
    }

    private fun stopService() {
        isRunning = false
        recognitionEngine?.stopListening()
        ttsEngine?.stop()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun setupRecognitionFlow() {
        recognitionEngine?.let { engine ->
            serviceScope.launch {
                engine.finalResults.collect { text ->
                    translateAndSpeak(text)
                }
            }
            serviceScope.launch {
                engine.errors.collect { error ->
                    _recognitionStatus.value = RecognitionStatus.ERROR(error.message)
                }
            }
        }
    }

    private suspend fun translateAndSpeak(text: String) {
        _recognitionStatus.value = RecognitionStatus.TRANSLATING
        try {
            val direction = when (targetLanguage) {
                "Dog" -> TranslationDirection.HumanToDog
                "Cat" -> TranslationDirection.HumanToCat
                "Bird" -> TranslationDirection.HumanToBird
                else -> TranslationDirection.HumanToDog
            }
            val result = translationRouter?.translateAuto(text, targetLanguage.lowercase())
                ?: TranslationResult(
                    inputText = text,
                    outputText = text,
                    direction = direction,
                    confidence = 0.0,
                    qualityScore = null,
                    source = com.wooftalk.domain.model.TranslationSource.Simple
                )
            _translationResults.tryEmit(result)
            ttsEngine?.speak(result.outputText, utteranceId = result.inputText)
            _recognitionStatus.value = RecognitionStatus.SPEAKING
        } catch (e: Exception) {
            _recognitionStatus.value = RecognitionStatus.ERROR(e.message ?: "Translation failed")
        }
    }

    fun startListening() {
        _recognitionStatus.value = RecognitionStatus.LISTENING
        recognitionEngine?.startListening()
    }

    fun stopListening() {
        recognitionEngine?.stopListening()
        _recognitionStatus.value = RecognitionStatus.IDLE
    }

    fun setTranslationRouter(router: MultiLanguageRouter) {
        this.translationRouter = router
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("WoofTalk Voice")
            .setContentText("Listening for speech...")
            .setSmallIcon(R.drawable.ic_mic)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Stop",
                createStopPendingIntent()
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Voice Translation",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when voice translation is active"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createStopPendingIntent(): android.app.PendingIntent {
        val intent = Intent(this, VoiceTranslationService::class.java).apply {
            action = ACTION_STOP
        }
        return android.app.PendingIntent.getService(
            this, 0, intent,
            android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    companion object {
        const val CHANNEL_ID = "voice_translation_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.wooftalk.ACTION_START"
        const val ACTION_STOP = "com.wooftalk.ACTION_STOP"
    }
}

enum class RecognitionStatus {
    IDLE, LISTENING, TRANSLATING, SPEAKING;
    data class Error(val message: String) : RecognitionStatus()
}
