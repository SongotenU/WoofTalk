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
    fun providePurchases(app: android.app.Application): Purchases {
        val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
        val config = PurchasesConfiguration.Builder(app, apiKey)
            // Don't set appUserID here - will be set later via login
            .build()
        Purchases.configure(config)
        return Purchases.sharedInstance
    }
}
