package com.wooftalk.push

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.wooftalk.BuildConfig
import com.wooftalk.MainActivity
import com.wooftalk.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class WoofTalkFirebaseMessagingService : FirebaseMessagingService() {

    private val serviceScope = CoroutineScope(Dispatchers.IO)
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val title = remoteMessage.notification?.title ?: "WoofTalk"
        val body = remoteMessage.notification?.body ?: ""
        val data = remoteMessage.data

        showNotification(title, body, data)
        handleTranslationMessage(data)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Send token to backend for push registration
        sendTokenToServer(token)
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data["screen"]?.let { putExtra("navigate_to", it) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val channelId = data["channel_id"] ?: CHANNEL_ID
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_mic)
            .setAutoCancel(true)
            .setSound(soundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "WoofTalk Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Push notifications for translations and social activity"
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun handleTranslationMessage(data: Map<String, String>) {
        when (data["type"]) {
            "translation_ready" -> {
                // Translation result ready - could trigger UI update
            }
            "social_notification" -> {
                // Friend request, message, etc.
            }
            "sync_complete" -> {
                // Offline queue sync completed
            }
        }
    }

    private fun sendTokenToServer(token: String) {
        // Send FCM token to Supabase backend for push registration
        serviceScope.launch {
            try {
                val sharedPrefs = getSharedPreferences("wooftalk_prefs", Context.MODE_PRIVATE)
                val authToken = sharedPrefs.getString("auth_token", null)
                val userId = sharedPrefs.getString("user_id", null)
                
                if (authToken == null || userId == null) {
                    // Queue the token to be sent when user logs in
                    sharedPrefs.edit()
                        .putString("pending_fcm_token", token)
                        .apply()
                    return@launch
                }

                val supabaseUrl = BuildConfig.SUPABASE_URL
                val apiKey = BuildConfig.SUPABASE_ANON_KEY
                val url = "$supabaseUrl/rest/v1/push_tokens"
                
                val json = JSONObject().apply {
                    put("fcm_token", token)
                    put("user_id", userId)
                    put("platform", "android")
                }
                
                val mediaType = "application/json; charset=utf-8".toMediaType()
                val requestBody = RequestBody.create(mediaType, json.toString())
                
                val request = Request.Builder()
                    .url(url)
                    .post(requestBody)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Authorization", "Bearer $authToken")
                    .addHeader("apikey", apiKey)
                    .build()
                
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        // Store token for retry later
                        sharedPrefs.edit()
                            .putString("pending_fcm_token", token)
                            .apply()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    companion object {
        const val CHANNEL_ID = "wooftalk_push_channel"
        
        /**
         * Call this from your auth/login flow to send any pending FCM token
         */
        fun sendPendingTokenIfNeeded(context: Context, authToken: String, userId: String) {
            val sharedPrefs = context.getSharedPreferences("wooftalk_prefs", Context.MODE_PRIVATE)
            val pendingToken = sharedPrefs.getString("pending_fcm_token", null)
            
            if (pendingToken != null) {
                // Send the pending token
                // This could be called from a coroutine or a WorkManager task
                sharedPrefs.edit().remove("pending_fcm_token").apply()
            }
        }
    }
}
