package com.wooftalk

import com.wooftalk.sync.conflict.ConflictResolver
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class ConflictResolverTest {
    private lateinit var resolver: ConflictResolver

    @Before
    fun setup() {
        resolver = ConflictResolver()
    }

    @Test
    fun `translation last-write-wins local newer`() {
        val result = resolver.resolveTranslation(
            localTimestamp = 2000,
            remoteTimestamp = 1000,
            localText = "local",
            remoteText = "remote"
        )
        assertTrue(result is ConflictResolver.Resolution.UseLocal)
    }

    @Test
    fun `translation last-write-wins remote newer`() {
        val result = resolver.resolveTranslation(
            localTimestamp = 1000,
            remoteTimestamp = 2000,
            localText = "local",
            remoteText = "remote"
        )
        assertTrue(result is ConflictResolver.Resolution.UseRemote)
    }

    @Test
    fun `follow relationships merge`() {
        val result = resolver.resolveFollowRelationships(
            localFollows = setOf("user1", "user2"),
            remoteFollows = setOf("user2", "user3")
        )
        assertTrue(result is ConflictResolver.Resolution.Merge)
    }

    @Test
    fun `votes max wins`() {
        val result = resolver.resolveVotes(
            localUpvotes = 5,
            localDownvotes = 2,
            remoteUpvotes = 3,
            remoteDownvotes = 4
        )
        assertTrue(result is ConflictResolver.Resolution.Merge)
    }

    @Test
    fun `leaderboard server authoritative`() {
        val result = resolver.resolveLeaderboard(
            localScore = 100,
            remoteScore = 50
        )
        assertTrue(result is ConflictResolver.Resolution.UseRemote)
    }

    @Test
    fun `same timestamp uses local`() {
        val result = resolver.resolveTranslation(
            localTimestamp = 1000,
            remoteTimestamp = 1000,
            localText = "local",
            remoteText = "remote"
        )
        assertTrue(result is ConflictResolver.Resolution.UseLocal)
    }
}
