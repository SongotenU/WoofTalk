package com.wooftalk.domain.repository

import com.wooftalk.data.remote.api.*
import com.wooftalk.data.remote.model.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.withContext

class SocialRepository(
    private val api: WoofTalkApi,
    private val currentUserId: () -> String
) {
    suspend fun getLeaderboard(period: String = "all_time", limit: Int = 50): List<RemoteLeaderboardEntry> =
        withContext(Dispatchers.IO) {
            val response = api.getLeaderboard(period, limit)
            if (response.isSuccessful) response.body()?.leaderboard ?: emptyList()
            else emptyList()
        }

    suspend fun followUser(userId: String): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val response = api.followUser(FollowRequest(currentUserId(), userId))
                response.isSuccessful
            } catch (e: Exception) { false }
        }

    suspend fun unfollowUser(userId: String): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val response = api.unfollowUser(currentUserId(), userId)
                response.isSuccessful
            } catch (e: Exception) { false }
        }

    fun getFollowing(): Flow<List<FollowRelationship>> = flow {
        try {
            val response = api.getFollowing(currentUserId())
            if (response.isSuccessful) emit(response.body() ?: emptyList())
            else emit(emptyList())
        } catch (e: Exception) { emit(emptyList()) }
    }

    suspend fun submitActivityEvents(events: List<ActivityEventItem>): Int =
        withContext(Dispatchers.IO) {
            try {
                val response = api.submitActivityEvents(ActivityBatchRequest(events))
                if (response.isSuccessful) response.body()?.created ?: 0 else 0
            } catch (e: Exception) { 0 }
        }
}
