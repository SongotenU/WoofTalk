package com.wooftalk

import android.app.Activity
import androidx.compose.runtime.*
import com.revenuecat.purchases.Entitlement
import com.revenuecat.purchases.EntitlementInfo
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.models.StoreTransaction
import dagger.hilt.android.scopes.ActivityRetainedScoped
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*
import javax.inject.Inject

@ActivityRetainedScoped
class EntitlementManager @Inject constructor() {

    companion object {
        private const val TAG = "EntitlementManager"
    }

    private val _isPremium = MutableStateFlow(false)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    private val _isTrialActive = MutableStateFlow(false)
    val isTrialActive: StateFlow<Boolean> = _isTrialActive.asStateFlow()

    private val _isReadyToAccessPaywall = MutableStateFlow(false)
    val isReadyToAccessPaywall: StateFlow<Boolean> = _isReadyToAccessPaywall.asStateFlow()

    private val _offerings = MutableStateFlow<Any?>(null)
    val offerings: StateFlow<Any?> = _offerings.asStateFlow()

    private val _purchaseEvent = Channel<PurchaseEvent>(Channel.BUFFERED)
    val purchaseEvent = _purchaseEvent.receiveAsFlow()

    val isLoading: StateFlow<Boolean> = MutableStateFlow(false)

    fun login(userId: String) {
        Purchases.sharedInstance.logIn(
            userId,
            onError = { error ->
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
            },
            onSuccess = { customerInfo, created ->
                checkEntitlements()
            }
        )
    }

    fun logout() {
        Purchases.sharedInstance.logOut(
            onError = { error ->
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
            },
            onSuccess = { customerInfo ->
                checkEntitlements()
            }
        )
    }

    fun checkEntitlements() {
        val customerInfo = Purchases.sharedInstance.customerInfo
        val entitlements = customerInfo.entitlements.active
        _isPremium.value = entitlements.containsKey("premium")
        _isTrialActive.value = customerInfo.entitlements.active.values.any { it.isActive }
    }

    fun refreshOfferings() {
        Purchases.sharedInstance.getOfferings(
            onError = { error ->
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
                _isReadyToAccessPaywall.value = false
            },
            onSuccess = { offerings ->
                _offerings.value = offerings
                _isReadyToAccessPaywall.value = true
            }
        )
    }

    fun purchasePackage(
        activity: Activity,
        rcPackage: Package
    ) {
        Purchases.sharedInstance.purchase(
            activity,
            rcPackage,
            object : PurchaseCallback {
                override fun onCompleted(storeTransaction: StoreTransaction, customerInfo: com.revenuecat.purchases.CustomerInfo) {
                    checkEntitlements()
                    _purchaseEvent.trySend(PurchaseEvent.Success)
                }

                override fun onError(error: PurchasesError, userCancelled: Boolean) {
                    if (userCancelled) {
                        _purchaseEvent.trySend(PurchaseEvent.Cancelled)
                    } else {
                        _purchaseEvent.trySend(PurchaseEvent.Error(error))
                    }
                }
            }
        )
    }

    fun restorePurchases() {
        Purchases.sharedInstance.restorePurchases(
            onError = { error ->
                _purchaseEvent.trySend(PurchaseEvent.Error(error))
            },
            onSuccess = { customerInfo ->
                checkEntitlements()
                _purchaseEvent.trySend(PurchaseEvent.Restored)
            }
        )
    }

    fun getActiveEntitlements(): List<String> {
        val customerInfo = Purchases.sharedInstance.customerInfo
        return customerInfo.entitlements.active.keys.toList()
    }
}

sealed class PurchaseEvent {
    object Success : PurchaseEvent()
    object Cancelled : PurchaseEvent()
    object Restored : PurchaseEvent()
    data class Error(val error: Any?) : PurchaseEvent()
}
