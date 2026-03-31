package com.wooftalk.sync.manager

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import com.wooftalk.sync.queue.OfflineWriteQueueDao
import com.wooftalk.sync.queue.QueuedOperation
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class SyncManager(
    private val context: Context,
    private val queueDao: OfflineWriteQueueDao,
    private val syncApi: SyncApi
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var isOnline = false
    private var syncJob: Job? = null

    private val _syncStatus = MutableStateFlow<SyncStatus>(SyncStatus.Idle)
    val syncStatus: StateFlow<SyncStatus> = _syncStatus.asStateFlow()

    private val _pendingCount = MutableStateFlow(0)
    val pendingCount: StateFlow<Int> = _pendingCount.asStateFlow()

    init {
        setupNetworkMonitoring()
        startSyncLoop()
    }

    private fun setupNetworkMonitoring() {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(networkRequest, object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                isOnline = true
                scope.launch { flushQueue() }
            }
            override fun onLost(network: Network) {
                isOnline = false
                _syncStatus.value = SyncStatus.Offline
            }
        })

        isOnline = connectivityManager.activeNetwork?.let { network ->
            connectivityManager.getNetworkCapabilities(network)?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        } ?: false
    }

    private fun startSyncLoop() {
        scope.launch {
            while (isActive) {
                delay(SYNC_INTERVAL_MS)
                if (isOnline) {
                    flushQueue()
                }
            }
        }
    }

    suspend fun enqueueOperation(operation: QueuedOperation) {
        queueDao.enqueue(operation)
        _pendingCount.value = queueDao.getPendingCount()
        if (isOnline) {
            flushQueue()
        }
    }

    private suspend fun flushQueue() {
        if (syncJob?.isActive == true) return
        syncJob = scope.launch {
            _syncStatus.value = SyncStatus.Syncing
            try {
                val operations = queueDao.getPendingOperationsBatch(50)
                var successCount = 0
                var failCount = 0

                for (op in operations) {
                    try {
                        syncApi.executeOperation(op)
                        queueDao.markCompleted(op.id)
                        successCount++
                    } catch (e: Exception) {
                        val nextRetryAt = System.currentTimeMillis() + calculateBackoff(op.retryCount)
                        queueDao.markFailed(op.id, e.message ?: "Unknown error", nextRetryAt)
                        failCount++
                    }
                }

                queueDao.deleteCompleted(System.currentTimeMillis() - 24 * 60 * 60 * 1000L)
                queueDao.deleteExhaustedRetries()
                _pendingCount.value = queueDao.getPendingCount()
                _syncStatus.value = if (failCount > 0) SyncStatus.PartialSync else SyncStatus.Synced
            } catch (e: Exception) {
                _syncStatus.value = SyncStatus.Error(e.message ?: "Sync failed")
            }
        }
    }

    private fun calculateBackoff(retryCount: Int): Long {
        val baseDelay = 1000L
        val maxDelay = 300000L
        return (baseDelay * (1L shl retryCount)).coerceAtMost(maxDelay)
    }

    suspend fun forceSync() {
        isOnline = true
        flushQueue()
    }

    fun destroy() {
        syncJob?.cancel()
        scope.cancel()
    }

    companion object {
        const val SYNC_INTERVAL_MS = 30000L
    }
}

sealed class SyncStatus {
    object Idle : SyncStatus()
    object Syncing : SyncStatus()
    object Synced : SyncStatus()
    object PartialSync : SyncStatus()
    object Offline : SyncStatus()
    data class Error(val message: String) : SyncStatus()
}
