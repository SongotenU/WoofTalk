package com.wooftalk.data.local.dao

import androidx.room.*
import com.wooftalk.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id")
    fun getUserById(id: UUID): Flow<UserEntity?>

    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUserByIdOnce(id: UUID): UserEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Update
    suspend fun updateUser(user: UserEntity)

    @Query("UPDATE users SET displayName = :name, avatarUrl = :avatarUrl WHERE id = :id")
    suspend fun updateProfile(id: UUID, name: String, avatarUrl: String?)

    @Query("UPDATE users SET isPremium = :isPremium, subscriptionExpiry = :expiry WHERE id = :id")
    suspend fun updateSubscription(id: UUID, isPremium: Boolean, expiry: Long?)

    @Delete
    suspend fun deleteUser(user: UserEntity)
}
