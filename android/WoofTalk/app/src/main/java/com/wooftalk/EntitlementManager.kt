package com.wooftalk

import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EntitlementManager @Inject constructor() : UpdatedCustomerInfoListener {

    private val _isPremium = MutableStateFlow(false)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    private val _isTrialActive = MutableStateFlow(false)
    val isTrialActive: StateFlow<Boolean> = _isTrialActive.asStateFlow()

    private val _dailyTranslationsUsed = MutableStateFlow(0)
    val dailyTranslationsUsed: StateFlow<Int> = _dailyTranslationsUsed.asStateFlow()

    private val _subscriptionTier = MutableStateFlow("free")
    val subscriptionTier: StateFlow<String> = _subscriptionTier.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    // SDK-06: Unauthenticated users cannot access paywall
    val isReadyToAccessPaywall: StateFlow<Boolean>
        get() = _isAuthenticated.asStateFlow()

    init {
        Purchases.sharedInstance.updatedCustomerInfoListener = this
    }

    // UpdatedCustomerInfoListener — fires on any CustomerInfo change (SDK-04)
    override fun onCustomerInfoUpdated(customerInfo: CustomerInfo) {
        updateFromCustomerInfo(customerInfo)
    }

    private fun updateFromCustomerInfo(customerInfo: CustomerInfo) {
        val proEntitlement = customerInfo.entitlements["pro"]
        val isPremiumActive = proEntitlement?.isActive == true
        _isPremium.value = isPremiumActive

        // Detect trial: active entitlement but no active paid subscriptions
        val isTrial = isPremiumActive && customerInfo.activeSubscriptions.isEmpty()
        _isTrialActive.value = isTrial

        _subscriptionTier.value = when {
            isPremiumActive && !isTrial -> "pro"
            isPremiumActive && isTrial -> "trial"
            else -> "free"
        }
    }

    // D-01/D-02: Call after Supabase auth resolves with auth.uid
    suspend fun logIn(authUid: String) {
        val result = Purchases.sharedInstance.login(authUid)
        updateFromCustomerInfo(result.customerInfo)
        _isAuthenticated.value = true
    }

    // Call on sign-out
    suspend fun logOut() {
        Purchases.sharedInstance.logOut()
        _isAuthenticated.value = false
        _isPremium.value = false
        _isTrialActive.value = false
        _subscriptionTier.value = "free"
    }

    // SDK-05 / Pitfall 2: Force refresh after purchase
    suspend fun refreshEntitlements() {
        _isLoading.value = true
        try {
            val customerInfo = Purchases.sharedInstance.getCustomerInfo()
            updateFromCustomerInfo(customerInfo)
        } catch (_: Exception) {
            // D-05: Trust cached CustomerInfo when offline
        } finally {
            _isLoading.value = false
        }
    }

    // Convenience: check entitlements on foreground / significant events
    suspend fun checkEntitlements() {
        try {
            val customerInfo = Purchases.sharedInstance.getCustomerInfo()
            updateFromCustomerInfo(customerInfo)
        } catch (_: Exception) {
            // D-05: Trust cached CustomerInfo when offline
        }
    }
}
