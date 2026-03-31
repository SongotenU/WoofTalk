package com.wooftalk.wear.data

import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow

object SupabaseClient {
    private const val SUPABASE_URL = BuildConfig.SUPABASE_URL
    private const val SUPABASE_ANON_KEY = BuildConfig.SUPABASE_ANON_KEY

    val client = createSupabaseClient(
        supabaseUrl = SUPABASE_URL,
        supabaseKey = SUPABASE_ANON_KEY
    ) {
        install(Postgrest)
        install(Realtime)
    }

    suspend fun fetchTranslations(userId: String): List<TranslationRecord> {
        return client.from("translations")
            .select {
                filter {
                    eq("user_id", userId)
                }
            }
            .decodeList<TranslationRecord>()
    }

    suspend fun saveTranslation(translation: TranslationRecord) {
        client.from("translations").insert(translation)
    }

    fun translationChanges(userId: String): Flow<Map<String, Any?>> {
        return client.postgresChangeFlow(
            schema = "public",
            table = "translations"
        ) {
            filter {
                eq("user_id", userId)
            }
        }
    }
}

data class TranslationRecord(
    val id: String? = null,
    val human_text: String,
    val animal_text: String,
    val source_language: String,
    val target_language: String,
    val confidence: Double,
    val user_id: String,
    val created_at: String? = null
)
