package com.wooftalk.sync.conflict

class ConflictResolver {
    sealed class Resolution {
        data class UseLocal(val reason: String) : Resolution()
        data class UseRemote(val reason: String) : Resolution()
        data class Merge(val reason: String) : Resolution()
    }

    fun resolveTranslation(
        localTimestamp: Long,
        remoteTimestamp: Long,
        localText: String,
        remoteText: String
    ): Resolution {
        return if (localTimestamp >= remoteTimestamp) {
            Resolution.UseLocal("Last-write-wins: local is newer")
        } else {
            Resolution.UseRemote("Last-write-wins: remote is newer")
        }
    }

    fun resolveFollowRelationships(
        localFollows: Set<String>,
        remoteFollows: Set<String>
    ): Resolution {
        val merged = localFollows + remoteFollows
        return Resolution.Merge("Union of follow relationships: ${merged.size} total")
    }

    fun resolveVotes(
        localUpvotes: Int,
        localDownvotes: Int,
        remoteUpvotes: Int,
        remoteDownvotes: Int
    ): Resolution {
        val mergedUpvotes = maxOf(localUpvotes, remoteUpvotes)
        val mergedDownvotes = maxOf(localDownvotes, remoteDownvotes)
        return Resolution.Merge("Max wins: $mergedUpvotes up, $mergedDownvotes down")
    }

    fun resolveLeaderboard(
        localScore: Int,
        remoteScore: Int
    ): Resolution {
        return Resolution.UseRemote("Server-authoritative for leaderboard")
    }
}
