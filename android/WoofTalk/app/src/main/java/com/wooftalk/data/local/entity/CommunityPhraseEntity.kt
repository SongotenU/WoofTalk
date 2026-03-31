package com.wooftalk.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Index
import java.util.UUID

@Entity(
    tableName = "community_phrases",
    indices = [
        Index(value = ["language"]),
        Index(value = ["approvalStatus"]),
        Index(value = ["upvotes", "downvotes"])
    ]
)
data class CommunityPhraseEntity(
    @PrimaryKey val id: UUID = UUID.randomUUID(),
    val phraseText: String,
    val language: String = "dog",
    val submittedBy: String? = null,
    val approvalStatus: String = "approved",
    val upvotes: Int = 0,
    val downvotes: Int = 0,
    val createdAt: Long = System.currentTimeMillis()
)
