package com.wooftalk.sync.manager

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class SyncVerifier {
    private val _syncMetrics = MutableStateFlow(SyncMetrics())
    val syncMetrics: StateFlow<SyncMetrics> = _syncMetrics.asStateFlow()

    private var lastSyncTimestamp = 0L
    private var syncCount = 0
    private var errorCount = 0
    private var totalLatency = 0L

    fun recordSyncStart() {
        lastSyncTimestamp = System.currentTimeMillis()
    }

    fun recordSyncSuccess() {
        val latency = System.currentTimeMillis() - lastSyncTimestamp
        syncCount++
        totalLatency += latency
        _syncMetrics.value = SyncMetrics(
            totalSyncs = syncCount,
            totalErrors = errorCount,
            averageLatencyMs = if (syncCount > 0) totalLatency / syncCount else 0,
            lastSyncTimestamp = lastSyncTimestamp,
            isConsistent = errorCount == 0
        )
    }

    fun recordSyncError(error: String) {
        errorCount++
        _syncMetrics.value = _syncMetrics.value.copy(
            totalErrors = errorCount,
            lastError = error,
            isConsistent = false
        )
    }

    fun reset() {
        syncCount = 0
        errorCount = 0
        totalLatency = 0
        _syncMetrics.value = SyncMetrics()
    }
}

data class SyncMetrics(
    val totalSyncs: Int = 0,
    val totalErrors: Int = 0,
    val averageLatencyMs: Long = 0,
    val lastSyncTimestamp: Long = 0,
    val lastError: String? = null,
    val isConsistent: Boolean = true
)
