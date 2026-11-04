package com.zadkiel.musclecheck.analytics

import java.time.Duration
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton

/**
 * When the app last came to the foreground, for `seconds_since_open`: the number that says
 * whether a check really takes "2 seconds". Marked by the Application's process-lifecycle
 * observer, so returning from Settings or a sheet does not restart it (the iOS twin keys on
 * scenePhase `.active` for the same reason).
 */
@Singleton
class AppOpenClock @Inject constructor() {

    @Volatile private var openedAt: Instant? = null

    fun markOpened(now: Instant = Instant.now()) {
        openedAt = now
    }

    /** Null while no open was recorded: the parameter is then left out, not sent as 0. */
    fun secondsSinceOpen(now: Instant = Instant.now()): Long? =
        openedAt?.let { Duration.between(it, now).seconds.coerceAtLeast(0) }
}
