package com.wooftalk.ui.screen

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.ui.revenuecatui.Paywall
import com.revenuecat.purchases.ui.revenuecatui.PaywallListener
import com.revenuecat.purchases.ui.revenuecatui.PaywallOptions
import com.wooftalk.EntitlementManager
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

@Composable
fun PaywallScreen(
    entitlementManager: EntitlementManager,
    onDismiss: () -> Unit
) {
    // Observe entitlement state to detect purchase confirmation
    val isPremium by entitlementManager.isPremium.collectAsState()
    val isLoading by entitlementManager.isLoading.collectAsState()

    Paywall(
        options = PaywallOptions.Builder()
            .setListener(object : PaywallListener {
                override fun onPurchaseCompleted(customerInfo: CustomerInfo) {
                    // Refresh entitlements after successful purchase
                    MainScope().launch {
                        entitlementManager.refreshEntitlements()
                        onDismiss()
                    }
                }
                override fun onRestoreCompleted(customerInfo: CustomerInfo) {
                    // Refresh entitlements after restore purchase
                    MainScope().launch {
                        entitlementManager.refreshEntitlements()
                        onDismiss()
                    }
                }
            })
            .build()
    )

    // Auto-dismiss paywall when entitlement state changes
    if (isPremium && !isLoading) {
        onDismiss()
    }
}