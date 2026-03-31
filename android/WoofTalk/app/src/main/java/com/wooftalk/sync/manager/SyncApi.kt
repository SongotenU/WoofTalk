package com.wooftalk.sync.manager

import com.wooftalk.sync.queue.QueuedOperation
import com.wooftalk.data.remote.api.WoofTalkApi
import com.google.gson.Gson

class SyncApi(
    private val api: WoofTalkApi,
    private val gson: Gson = Gson()
) {
    suspend fun executeOperation(operation: QueuedOperation) {
        when (operation.operationType) {
            "translation" -> {
                val data = gson.fromJson(operation.payload, TranslationSyncData::class.java)
                api.logTranslation(
                    com.wooftalk.data.remote.api.TranslationRequest(
                        humanText = data.humanText,
                        animalText = data.animalText,
                        sourceLanguage = data.sourceLanguage,
                        targetLanguage = data.targetLanguage,
                        confidence = data.confidence,
                        qualityScore = data.qualityScore
                    )
                )
            }
            "phrase" -> {
                val data = gson.fromJson(operation.payload, PhraseSyncData::class.java)
                api.submitPhrase(
                    com.wooftalk.data.remote.api.PhraseSubmissionRequest(
                        phraseText = data.phraseText,
                        language = data.language,
                        submittedBy = data.submittedBy,
                        approvalStatus = "pending"
                    )
                )
            }
            "follow" -> {
                val data = gson.fromJson(operation.payload, FollowSyncData::class.java)
                api.followUser(com.wooftalk.data.remote.api.FollowRequest(data.followerId, data.followingId))
            }
            "unfollow" -> {
                val data = gson.fromJson(operation.payload, UnfollowSyncData::class.java)
                api.unfollowUser(data.followerId, data.followingId)
            }
            else -> throw IllegalArgumentException("Unknown operation type: ${operation.operationType}")
        }
    }
}

data class TranslationSyncData(
    val humanText: String,
    val animalText: String,
    val sourceLanguage: String,
    val targetLanguage: String,
    val confidence: Double,
    val qualityScore: Double?
)

data class PhraseSyncData(
    val phraseText: String,
    val language: String,
    val submittedBy: String
)

data class FollowSyncData(val followerId: String, val followingId: String)
data class UnfollowSyncData(val followerId: String, val followingId: String)
