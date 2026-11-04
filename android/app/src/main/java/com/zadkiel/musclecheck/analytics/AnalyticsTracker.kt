package com.zadkiel.musclecheck.analytics

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.firebase.analytics.FirebaseAnalytics

/**
 * Analytics seam (docs/analytics-plan.md §11), the twin of the iOS `AnalyticsTracking`.
 * Firebase is ONE implementation: tests inject a spy, so test runs never reach real data.
 * Which implementation the app gets is decided in `AppModule`.
 */
interface AnalyticsTracker {
    fun track(event: AnalyticsEvent)
}

class FirebaseAnalyticsTracker(
    context: Context,
    private val echoToLogcat: Boolean = false,
) : AnalyticsTracker {

    private val firebase = FirebaseAnalytics.getInstance(context)

    override fun track(event: AnalyticsEvent) {
        if (echoToLogcat) LogcatAnalytics.track(event)
        val params = Bundle().apply {
            event.parameters.forEach { (key, value) ->
                when (value) {
                    is Long -> putLong(key, value)
                    else -> putString(key, value.toString())
                }
            }
        }
        firebase.logEvent(event.name, params)
    }
}

/** Debug builds: prints the event and sends nothing. */
object LogcatAnalytics : AnalyticsTracker {
    override fun track(event: AnalyticsEvent) {
        Log.d("Analytics", "${event.name} ${event.parameters}")
    }
}
