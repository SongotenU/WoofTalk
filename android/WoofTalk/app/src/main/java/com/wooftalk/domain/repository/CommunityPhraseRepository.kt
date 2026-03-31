package com.wooftalk.domain.repository

import com.wooftalk.data.local.dao.CommunityPhraseDao
import com.wooftalk.data.local.entity.CommunityPhraseEntity
import com.wooftalk.data.remote.api.WoofTalkApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.util.UUID

class CommunityPhraseRepository(
    private val dao: CommunityPhraseDao,
    private val api: WoofTalkApi
) {
    fun getApprovedPhrases(language: String? = null, limit: Int = 50): Flow<List<CommunityPhraseEntity>> =
        if (language != null) dao.getPhrasesByLanguage(language, limit)
        else dao.getApprovedPhrases(limit)

    suspend fun searchPhrases(query: String, language: String? = null, limit: Int = 20): List<CommunityPhraseEntity> =
        withContext(Dispatchers.IO) {
            val localResults = dao.searchPhrases(query, limit)
            if (localResults.isNotEmpty()) {
                localResults
            } else {
                try {
                    val response = api.searchPhrases(query, language, limit)
                    if (response.isSuccessful) {
                        response.body()?.phrases?.map { remote ->
                            CommunityPhraseEntity(
                                id = UUID.fromString(remote.id),
                                phraseText = remote.phraseText,
                                language = remote.language,
                                submittedBy = remote.submittedBy,
                                approvalStatus = remote.approvalStatus,
                                upvotes = remote.upvotes,
                                downvotes = remote.downvotes,
                                createdAt = parseTimestamp(remote.createdAt)
                            )
                        } ?: emptyList()
                    } else emptyList()
                } catch (e: Exception) {
                    emptyList()
                }
            }
        }

    suspend fun submitPhrase(phrase: CommunityPhraseEntity) {
        withContext(Dispatchers.IO) {
            dao.insertPhrase(phrase)
            try {
                api.submitPhrase(
                    com.wooftalk.data.remote.api.PhraseSubmissionRequest(
                        phraseText = phrase.phraseText,
                        language = phrase.language,
                        submittedBy = phrase.submittedBy ?: "",
                        approvalStatus = "pending"
                    )
                )
            } catch (e: Exception) {
                // Phrase saved locally, will sync later
            }
        }
    }

    suspend fun syncFromRemote() {
        withContext(Dispatchers.IO) {
            try {
                val response = api.searchPhrases("", null, 100)
                if (response.isSuccessful) {
                    val phrases = response.body()?.phrases?.map { remote ->
                        CommunityPhraseEntity(
                            id = UUID.fromString(remote.id),
                            phraseText = remote.phraseText,
                            language = remote.language,
                            submittedBy = remote.submittedBy,
                            approvalStatus = remote.approvalStatus,
                            upvotes = remote.upvotes,
                            downvotes = remote.downvotes,
                            createdAt = parseTimestamp(remote.createdAt)
                        )
                    } ?: emptyList()
                    dao.insertPhrases(phrases)
                }
            } catch (e: Exception) {
                // Sync failed, will retry later
            }
        }
    }

    suspend fun upvotePhrase(id: UUID) = dao.incrementUpvotes(id)
    suspend fun downvotePhrase(id: UUID) = dao.incrementDownvotes(id)

    private fun parseTimestamp(timestamp: String): Long =
        try { java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).parse(timestamp)?.time ?: System.currentTimeMillis() }
        catch (_: Exception) { System.currentTimeMillis() }
}
