package com.wooftalk.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.wooftalk.data.local.converter.Converters
import com.wooftalk.data.local.dao.CommunityPhraseDao
import com.wooftalk.data.local.dao.TranslationDao
import com.wooftalk.data.local.dao.UserDao
import com.wooftalk.data.local.entity.CommunityPhraseEntity
import com.wooftalk.data.local.entity.TranslationEntity
import com.wooftalk.data.local.entity.UserEntity

@Database(
    entities = [TranslationEntity::class, CommunityPhraseEntity::class, UserEntity::class],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun translationDao(): TranslationDao
    abstract fun communityPhraseDao(): CommunityPhraseDao
    abstract fun userDao(): UserDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "wooftalk_database"
                )
                .fallbackToDestructiveMigration()
                .build()
                .also { INSTANCE = it }
            }
    }
}
