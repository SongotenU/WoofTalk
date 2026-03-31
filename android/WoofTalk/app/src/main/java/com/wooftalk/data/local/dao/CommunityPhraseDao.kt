package com.wooftalk.data.local.dao

import androidx.room.*
import com.wooftalk.data.local.entity.CommunityPhraseEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface CommunityPhraseDao {
    @Query("SELECT * FROM community_phrases WHERE approvalStatus = 'approved' ORDER BY (upvotes - downvotes) DESC LIMIT :limit")
    fun getApprovedPhrases(limit: Int = 50): Flow<List<CommunityPhraseEntity>>

    @Query("SELECT * FROM community_phrases WHERE approvalStatus = 'approved' AND language = :language ORDER BY (upvotes - downvotes) DESC LIMIT :limit")
    fun getPhrasesByLanguage(language: String, limit: Int = 50): Flow<List<CommunityPhraseEntity>>

    @Query("SELECT * FROM community_phrases WHERE phraseText LIKE '%' || :query || '%' AND approvalStatus = 'approved' ORDER BY (upvotes - downvotes) DESC LIMIT :limit")
    suspend fun searchPhrases(query: String, limit: Int = 20): List<CommunityPhraseEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPhrase(phrase: CommunityPhraseEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPhrases(phrases: List<CommunityPhraseEntity>)

    @Update
    suspend fun updatePhrase(phrase: CommunityPhraseEntity)

    @Query("UPDATE community_phrases SET upvotes = upvotes + 1 WHERE id = :id")
    suspend fun incrementUpvotes(id: UUID)

    @Query("UPDATE community_phrases SET downvotes = downvotes + 1 WHERE id = :id")
    suspend fun incrementDownvotes(id: UUID)

    @Delete
    suspend fun deletePhrase(phrase: CommunityPhraseEntity)
}
