package com.zadkiel.musclecheck.data.pro

import com.zadkiel.musclecheck.BuildConfig

/**
 * Whether the app offers Pro for sale at all.
 *
 * Until RevenueCat is wired, [LocalProAccessManager.purchase] grants Pro without charging.
 * That's fine for exercising the paywall in debug builds, but a release build selling digital
 * goods outside Play Billing breaks Play's Payments policy, and it hands Pro out for free. So
 * release builds hide every way into the paywall and say Pro is coming instead. Flip this to
 * `true` together with the RevenueCat swap.
 */
object ProStore {
    val purchasesEnabled: Boolean = BuildConfig.DEBUG
}
