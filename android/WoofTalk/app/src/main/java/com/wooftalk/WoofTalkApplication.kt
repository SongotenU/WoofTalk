package com.wooftalk

import android.app.Application
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class WoofTalkApplication : Application() {
    @Inject lateinit var purchasesConfiguration: PurchasesConfiguration
    @Inject lateinit var entitlementManager: EntitlementManager

    override fun onCreate() {
        super.onCreate()
        Purchases.configure(purchasesConfiguration)
    }
}
