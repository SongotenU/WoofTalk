package com.wooftalk.data.remote.api

import com.wooftalk.data.remote.model.*
import retrofit2.Response
import retrofit2.http.*

interface WoofTalkApi {
    @GET("functions/v1/phrases-search")
    suspend fun searchPhrases(
        @Query("q") query: String,
        @Query("language") language: String?,
        @Query("limit") limit: Int = 20,
        @Query("offset") offset: Int = 0
    ): Response<PhraseSearchResponse>

    @GET("functions/v1/leaderboard")
    suspend fun getLeaderboard(
        @Query("period") period: String = "all_time",
        @Query("limit") limit: Int = 50
    ): Response<LeaderboardResponse>

    @POST("functions/v1/activity-batch")
    suspend fun submitActivityEvents(
        @Body request: ActivityBatchRequest
    ): Response<ActivityBatchResponse>

    @POST("functions/v1/translate")
    suspend fun logTranslation(
        @Body request: TranslationRequest
    ): Response<RemoteTranslation>

    @POST("phrases")
    suspend fun submitPhrase(
        @Body phrase: PhraseSubmissionRequest
    ): Response<RemotePhrase>

    @GET("follow_relationships")
    suspend fun getFollowing(
        @Query("follower_id") userId: String
    ): Response<List<FollowRelationship>>

    @POST("follow_relationships")
    suspend fun followUser(
        @Body request: FollowRequest
    ): Response<Unit>

    @DELETE("follow_relationships")
    suspend fun unfollowUser(
        @Query("follower_id") followerId: String,
        @Query("following_id") followingId: String
    ): Response<Unit>
}

data class PhraseSearchResponse(
    val phrases: List<RemotePhrase>,
    val total: Int
)

data class LeaderboardResponse(
    val leaderboard: List<RemoteLeaderboardEntry>,
    val period: String
)

data class ActivityBatchRequest(
    val events: List<ActivityEventItem>
)

data class ActivityEventItem(
    @SerializedName("event_type") val eventType: String,
    @SerializedName("event_data") val eventData: Map<String, Any>,
    val visibility: String = "public"
)

data class ActivityBatchResponse(
    val created: Int,
    val ids: List<String>
)

data class TranslationRequest(
    @SerializedName("human_text") val humanText: String,
    @SerializedName("animal_text") val animalText: String,
    @SerializedName("source_language") val sourceLanguage: String,
    @SerializedName("target_language") val targetLanguage: String,
    val confidence: Double,
    @SerializedName("quality_score") val qualityScore: Double?
)

data class PhraseSubmissionRequest(
    @SerializedName("phrase_text") val phraseText: String,
    val language: String,
    @SerializedName("submitted_by") val submittedBy: String,
    @SerializedName("approval_status") val approvalStatus: String = "pending"
)

data class FollowRelationship(
    @SerializedName("follower_id") val followerId: String,
    @SerializedName("following_id") val followingId: String,
    @SerializedName("created_at") val createdAt: String
)

data class FollowRequest(
    @SerializedName("follower_id") val followerId: String,
    @SerializedName("following_id") val followingId: String
)
