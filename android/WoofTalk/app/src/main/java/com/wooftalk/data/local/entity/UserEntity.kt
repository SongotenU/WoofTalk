package com.wooftalk.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: UUID,
    val email: String,
    val displayName: String = "",
    val avatarUrl: String? = null,
    val platform: String = "android",
    val isPremium: Boolean = false,
    val subscriptionExpiry: Long? = null,
    val createdAt: Long = System.currentTimeMillis()
)
