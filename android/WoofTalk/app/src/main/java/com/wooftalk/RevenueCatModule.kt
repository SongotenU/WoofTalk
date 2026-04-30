package com.wooftalk

import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.Purchases
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RevenueCatModule {

    @Provides
    @Singleton
    fun providePurchasesConfiguration(
        app: android.app.Application
    ): PurchasesConfiguration {
        val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
        return PurchasesConfiguration.Builder(app, apiKey)
            // FIX: Don't set appUserID here
            // RevenueCat will auto-generate an anonymous ID, and we can update it later
            // when the user logs in via Supabase using EntitlementManager.logIn()
            .build()
    }
}
