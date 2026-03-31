package com.wooftalk.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Index
import java.util.UUID

@Entity(
    tableName = "translations",
    indices = [
        Index(value = ["userId"]),
        Index(value = ["userId", "createdAt"]),
        Index(value = ["userId", "isFavorite"])
    ]
)
data class TranslationEntity(
    @PrimaryKey val id: UUID = UUID.randomUUID(),
    val userId: String? = null,
    val humanText: String,
    val animalText: String,
    val sourceLanguage: String = "human",
    val targetLanguage: String = "dog",
    val confidence: Double = 0.0,
    val qualityScore: Double? = null,
    val isFavorite: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
