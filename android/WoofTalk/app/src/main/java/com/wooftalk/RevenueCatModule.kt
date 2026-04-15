package com.wooftalk

import com.revenuecat.purchases.PurchasesConfiguration
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
            .appUserID(null)
            .build()
    }
}
