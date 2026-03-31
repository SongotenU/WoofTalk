package com.wooftalk.sync.queue

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "offline_write_queue", indices = [Index(value = ["priority"]), Index(value = ["status"]), Index(value = ["createdAt"])])
data class QueuedOperation(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val operationType: String,
    val payload: String,
    val priority: Int = 0,
    val retryCount: Int = 0,
    val maxRetries: Int = 5,
    val status: String = "pending",
    val errorMessage: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val nextRetryAt: Long? = null
)

@Dao
interface OfflineWriteQueueDao {
    @Query("SELECT * FROM offline_write_queue WHERE status = 'pending' ORDER BY priority DESC, createdAt ASC")
    fun getPendingOperations(): Flow<List<QueuedOperation>>

    @Query("SELECT * FROM offline_write_queue WHERE status = 'pending' ORDER BY priority DESC, createdAt ASC LIMIT :limit")
    suspend fun getPendingOperationsBatch(limit: Int = 50): List<QueuedOperation>

    @Query("SELECT * FROM offline_write_queue WHERE status = 'failed' ORDER BY nextRetryAt ASC")
    suspend fun getFailedOperations(): List<QueuedOperation>

    @Insert
    suspend fun enqueue(operation: QueuedOperation): Long

    @Insert
    suspend fun enqueueAll(operations: List<QueuedOperation>)

    @Query("UPDATE offline_write_queue SET status = 'completed' WHERE id = :id")
    suspend fun markCompleted(id: Long)

    @Query("UPDATE offline_write_queue SET status = 'failed', errorMessage = :error, retryCount = retryCount + 1, nextRetryAt = :nextRetryAt WHERE id = :id")
    suspend fun markFailed(id: Long, error: String, nextRetryAt: Long)

    @Query("UPDATE offline_write_queue SET status = 'pending', retryCount = 0, errorMessage = NULL WHERE id = :id")
    suspend fun resetForRetry(id: Long)

    @Query("DELETE FROM offline_write_queue WHERE status = 'completed' AND createdAt < :beforeTimestamp")
    suspend fun deleteCompleted(beforeTimestamp: Long)

    @Query("DELETE FROM offline_write_queue WHERE retryCount >= :maxRetries AND status = 'failed'")
    suspend fun deleteExhaustedRetries(maxRetries: Int = 10)

    @Query("SELECT COUNT(*) FROM offline_write_queue WHERE status = 'pending'")
    suspend fun getPendingCount(): Int

    @Query("SELECT COUNT(*) FROM offline_write_queue WHERE status = 'failed'")
    suspend fun getFailedCount(): Int
}
