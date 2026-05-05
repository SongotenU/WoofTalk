package com.wooftalk

import android.util.Log
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.models.CustomerInfo
import com.revenuecat.purchases.models.Offerings
import com.revenuecat.purchases.models.PeriodType
import dagger.hilt.android.scopes.ActivityRetainedScoped
import javax.inject.Inject
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow

@ActivityRetainedScoped
class EntitlementManager @Inject constructor(
    private val purchases: Purchases
) : UpdatedCustomerInfoListener {

    companion object {
        const val TAG = "EntitlementManager"
        const val ENTITLEMENT_ID = "premium"
    }

    private val _isPremium = MutableStateFlow(false)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    private val _isTrialActive = MutableStateFlow(false)
    val isTrialActive: StateFlow<Boolean> = _isTrialActive.asStateFlow()

    private val _isReadyToAccessPaywall = MutableStateFlow(false)
    val isReadyToAccessPaywall: StateFlow<Boolean> = _isReadyToAccessPaywall.asStateFlow()

    private val _offerings = MutableStateFlow<Offerings?>(null)
    val offerings: StateFlow<Offerings?> = _offerings.asStateFlow()

    private val _purchaseEvent = Channel<PurchaseEvent>(Channel.BUFFERED)
    val purchaseEvent = _purchaseEvent.receiveAsFlow()

    init {
        purchases.updatedCustomerInfoListener = this
    }

    override fun onReceived(customerInfo: CustomerInfo) {
        Log.d(TAG, "Customer info updated")
        updateEntitlements(customerInfo)
    }

    fun checkEntitlements() {
        val customerInfo = purchases.customerInfo
        updateEntitlements(customerInfo)
    }

    fun refreshOfferings() {
        purchases.getOfferings { offerings, error ->
            if (error != null) {
                Log.e(TAG, "Error getting offerings: ${error.message}")
                return@getOfferings
            }
            Log.d(TAG, "Offerings loaded")
            _offerings.value = offerings
            _isReadyToAccessPaywall.value = true
        }
    }

    fun purchasePackage(
        activity: android.app.Activity,
        rcPackage: com.revenuecat.purchases.models.Package
    ) {
        val params = com.revenuecat.purchases.PurchaseParams.Builder(activity, rcPackage).build()
        purchases.purchase(params) { _, customerInfo, error, userCancelled ->
            if (error != null) {
                Log.e(TAG, "Purchase error: ${error.message}")
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
                return@purchase
            }
            if (userCancelled) {
                Log.d(TAG, "User cancelled purchase")
                _purchaseEvent.trySend(PurchaseEvent.Cancelled)
                return@purchase
            }
            Log.d(TAG, "Purchase successful")
            updateEntitlements(customerInfo)
            _purchaseEvent.trySend(PurchaseEvent.Success)
        }
    }

    fun restorePurchases() {
        purchases.restorePurchases { customerInfo, error ->
            if (error != null) {
                Log.e(TAG, "Error restoring purchases: ${error.message}")
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
                return@restorePurchases
            }
            Log.d(TAG, "Restored purchases")
            updateEntitlements(customerInfo)
            _purchaseEvent.trySend(PurchaseEvent.Restored)
        }
    }

    private fun updateEntitlements(customerInfo: CustomerInfo) {
        val entitlement = customerInfo.entitlements[ENTITLEMENT_ID]
        val isPremium = entitlement?.isActive == true
        val isTrial = entitlement?.periodType == PeriodType.TRIAL

        _isPremium.value = isPremium
        _isTrialActive.value = isTrial

        Log.d(TAG, "Entitlements updated: premium=$isPremium, trial=$isTrial")
    }

    fun getActiveEntitlements(): List<String> {
        return purchases.customerInfo.entitlements
            .filterValues { it.isActive }
            .keys.toList()
    }
}

sealed class PurchaseEvent {
    object Success : PurchaseEvent()
    object Cancelled : PurchaseEvent()
    object Restored : PurchaseEvent()
    data class Error(val error: com.revenuecat.purchases.PurchasesError) : PurchaseEvent()
}
