package com.wooftalk

import android.app.Application
import android.util.Log
import com.revenuecat.purchases.PurchasesConfiguration

import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class WoofTalkApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize RevenueCat
        val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
        if (apiKey.isNotEmpty()) {
            Purchases.configure(
                PurchasesConfiguration.Builder(this, apiKey).build()
            )
            Log.d("WoofTalkApp", "RevenueCat initialized")
        } else {
            Log.w("WoofTalkApp", "RevenueCat API key not set")
        }
    }
}
