package com.wooftalk.data.local.dao

import androidx.room.*
import com.wooftalk.data.local.entity.TranslationEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface TranslationDao {
    @Query("SELECT * FROM translations ORDER BY createdAt DESC")
    fun getAllTranslations(): Flow<List<TranslationEntity>>

    @Query("SELECT * FROM translations WHERE userId = :userId ORDER BY createdAt DESC LIMIT :limit OFFSET :offset")
    suspend fun getTranslationsByUser(userId: String, limit: Int = 50, offset: Int = 0): List<TranslationEntity>

    @Query("SELECT * FROM translations WHERE userId = :userId AND isFavorite = 1 ORDER BY createdAt DESC")
    fun getFavoriteTranslations(userId: String): Flow<List<TranslationEntity>>

    @Query("SELECT * FROM translations WHERE humanText LIKE '%' || :query || '%' OR animalText LIKE '%' || :query || '%' ORDER BY createdAt DESC")
    suspend fun searchTranslations(query: String): List<TranslationEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTranslation(translation: TranslationEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTranslations(translations: List<TranslationEntity>)

    @Update
    suspend fun updateTranslation(translation: TranslationEntity)

    @Query("UPDATE translations SET isFavorite = :isFavorite WHERE id = :id")
    suspend fun updateFavorite(id: UUID, isFavorite: Boolean)

    @Delete
    suspend fun deleteTranslation(translation: TranslationEntity)

    @Query("DELETE FROM translations WHERE id = :id")
    suspend fun deleteTranslationById(id: UUID)

    @Query("SELECT COUNT(*) FROM translations")
    suspend fun getTranslationCount(): Int

    @Query("DELETE FROM translations WHERE createdAt < :beforeTimestamp")
    suspend fun deleteOldTranslations(beforeTimestamp: Long)
}
