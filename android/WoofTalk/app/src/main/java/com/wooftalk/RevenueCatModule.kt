package com.wooftalk

import android.content.Context
import com.revenuecat.purchases.Purchases
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
    fun providePurchases(application: android.app.Application): Purchases {
        val apiKey = BuildConfig.REVENUECAT_ANDROID_API_KEY
        Purchases.configure(
            PurchasesConfiguration.Builder(application, apiKey).build()
        )
        return Purchases.sharedInstance
    }
}
