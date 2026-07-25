package com.zadkiel.musclecheck.data.pro

import kotlinx.coroutines.flow.Flow

/** The three purchasable tiers — mirrors the iOS `PackageType`. */
enum class ProPackage { MONTHLY, YEARLY, LIFETIME }

/**
 * Source of truth for the user's Pro entitlement and the purchase flow.
 *
 * The rest of the app talks only to this interface (the Android mirror of the
 * iOS `StoreManagerProtocol` seam), so wiring the real RevenueCat SDK later is a
 * single-implementation swap — see [LocalProAccessManager] for the swap point.
 */
interface ProAccessManager {
    /** Whether the current user has an active Pro entitlement. */
    val isPro: Flow<Boolean>

    /** True while a purchase or restore is in flight. */
    val isLoading: Flow<Boolean>

    /** Buys [pkg]; grants the entitlement on success, throws [ProPurchaseException] on failure. */
    suspend fun purchase(pkg: ProPackage)

    /** Re-applies a previously-bought entitlement. */
    suspend fun restore()
}

class ProPurchaseException(message: String) : Exception(message)
