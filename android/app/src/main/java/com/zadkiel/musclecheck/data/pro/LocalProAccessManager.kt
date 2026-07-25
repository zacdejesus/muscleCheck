package com.zadkiel.musclecheck.data.pro

import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Local, DataStore-backed entitlement — the port's stand-in until RevenueCat is
 * wired. RevenueCat is blocked on external Play Console setup (paid developer
 * account, Play Billing products, and an Android public API key), so this keeps
 * the gate and paywall fully exercisable in the meantime: [purchase] grants the
 * entitlement locally instead of hitting the store.
 *
 * RevenueCat swap point — replace this class's body with the SDK calls; nothing
 * outside this file changes:
 *   - configure `Purchases` with the Android API key at app start;
 *   - `isPro`   ← `customerInfo.entitlements["pro"]?.isActive == true`;
 *   - `purchase`← `Purchases.sharedInstance.awaitPurchase(pkg.toRevenueCatPackage())`;
 *   - `restore` ← `Purchases.sharedInstance.awaitRestore()`.
 */
@Singleton
class LocalProAccessManager @Inject constructor(
    private val prefs: UserPreferencesRepository,
) : ProAccessManager {

    override val isPro: Flow<Boolean> = prefs.isPro

    private val _isLoading = MutableStateFlow(false)
    override val isLoading: Flow<Boolean> = _isLoading.asStateFlow()

    override suspend fun purchase(pkg: ProPackage) {
        _isLoading.value = true
        try {
            prefs.setPro(true)
        } finally {
            _isLoading.value = false
        }
    }

    override suspend fun restore() {
        // No remote receipts in the local stub — restore keeps whatever is stored.
    }
}
