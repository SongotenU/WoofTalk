package com.wooftalk.data.remote.model

import com.google.gson.annotations.SerializedName

data class RemotePhrase(
    @SerializedName("id") val id: String,
    @SerializedName("phrase_text") val phraseText: String,
    @SerializedName("language") val language: String,
    @SerializedName("submitted_by") val submittedBy: String?,
    @SerializedName("approval_status") val approvalStatus: String,
    @SerializedName("upvotes") val upvotes: Int,
    @SerializedName("downvotes") val downvotes: Int,
    @SerializedName("created_at") val createdAt: String
)

data class RemoteLeaderboardEntry(
    @SerializedName("rank") val rank: Int,
    @SerializedName("score") val score: Int,
    @SerializedName("period") val period: String,
    @SerializedName("users") val user: RemoteUser?
)

data class RemoteUser(
    @SerializedName("id") val id: String,
    @SerializedName("display_name") val displayName: String,
    @SerializedName("avatar_url") val avatarUrl: String?,
    @SerializedName("platform") val platform: String
)

data class RemoteActivityEvent(
    @SerializedName("id") val id: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("event_type") val eventType: String,
    @SerializedName("event_data") val eventData: Map<String, Any>,
    @SerializedName("visibility") val visibility: String,
    @SerializedName("created_at") val createdAt: String
)

data class RemoteTranslation(
    @SerializedName("id") val id: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("human_text") val humanText: String,
    @SerializedName("animal_text") val animalText: String,
    @SerializedName("source_language") val sourceLanguage: String,
    @SerializedName("target_language") val targetLanguage: String,
    @SerializedName("confidence") val confidence: Double,
    @SerializedName("quality_score") val qualityScore: Double?,
    @SerializedName("is_favorite") val isFavorite: Boolean,
    @SerializedName("created_at") val createdAt: String
)
