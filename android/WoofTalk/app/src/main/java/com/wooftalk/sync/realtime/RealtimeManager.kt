package com.wooftalk.sync.realtime

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*

class RealtimeManager {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var isConnected = false
    private var reconnectAttempts = 0

    private val _activityEvents = MutableSharedFlow<ActivityEvent>(extraBufferCapacity = 100)
    val activityEvents: SharedFlow<ActivityEvent> = _activityEvents.asSharedFlow()

    private val _connectionStatus = MutableStateFlow<ConnectionStatus>(ConnectionStatus.Disconnected)
    val connectionStatus: StateFlow<ConnectionStatus> = _connectionStatus.asStateFlow()

    fun connect(supabaseUrl: String, token: String) {
        scope.launch {
            while (isActive) {
                try {
                    _connectionStatus.value = ConnectionStatus.Connecting
                    isConnected = true
                    reconnectAttempts = 0
                    _connectionStatus.value = ConnectionStatus.Connected
                    awaitDisconnect()
                } catch (e: Exception) {
                    isConnected = false
                    reconnectAttempts++
                    val delay = minOf(1000L * (1L shl reconnectAttempts), 30000L)
                    _connectionStatus.value = ConnectionStatus.Reconnecting(reconnectAttempts, delay)
                    delay(delay)
                }
            }
        }
    }

    private suspend fun awaitDisconnect(): Nothing {
        while (isConnected) {
            delay(1000)
        }
        throw RuntimeException("Connection lost")
    }

    fun emitActivityEvent(event: ActivityEvent) {
        _activityEvents.tryEmit(event)
    }

    fun disconnect() {
        isConnected = false
        scope.cancel()
        _connectionStatus.value = ConnectionStatus.Disconnected
    }
}

sealed class ConnectionStatus {
    object Connected : ConnectionStatus()
    object Connecting : ConnectionStatus()
    object Disconnected : ConnectionStatus()
    data class Reconnecting(val attempt: Int, val nextRetryMs: Long) : ConnectionStatus()
}

data class ActivityEvent(
    val id: String,
    val userId: String,
    val eventType: String,
    val eventData: Map<String, Any>,
    val timestamp: Long
)
