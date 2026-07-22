package com.zadkiel.musclecheck.notifications

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * WorkManager port of the iOS `NotificationManager` scheduling: a repeating daily
 * reminder at the user's chosen time, plus a one-shot inactivity summary at 10 AM
 * tomorrow (re-enqueued every time the app goes to background, replacing the previous one).
 */
@Singleton
class ReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val workManager: WorkManager
        get() = WorkManager.getInstance(context)

    fun scheduleDailyReminder(hour: Int, minute: Int, now: LocalDateTime = LocalDateTime.now()) {
        val request = PeriodicWorkRequestBuilder<DailyReminderWorker>(Duration.ofDays(1))
            .setInitialDelay(delayUntilNext(hour, minute, now))
            .build()
        workManager.enqueueUniquePeriodicWork(DAILY_WORK, ExistingPeriodicWorkPolicy.REPLACE, request)
    }

    fun cancelDailyReminder() {
        workManager.cancelUniqueWork(DAILY_WORK)
    }

    fun scheduleInactivitySummary(now: LocalDateTime = LocalDateTime.now()) {
        val fireAt = LocalDateTime.of(now.toLocalDate().plusDays(1), INACTIVITY_FIRE_TIME)
        val request = OneTimeWorkRequestBuilder<InactivitySummaryWorker>()
            .setInitialDelay(Duration.between(now, fireAt))
            .build()
        workManager.enqueueUniqueWork(INACTIVITY_WORK, ExistingWorkPolicy.REPLACE, request)
    }

    fun cancelAll() {
        workManager.cancelUniqueWork(DAILY_WORK)
        workManager.cancelUniqueWork(INACTIVITY_WORK)
    }

    /** Delay until the next occurrence of hh:mm — today if still ahead, otherwise tomorrow. */
    internal fun delayUntilNext(hour: Int, minute: Int, now: LocalDateTime): Duration {
        val timeToday = LocalDateTime.of(now.toLocalDate(), LocalTime.of(hour, minute))
        val next = if (timeToday.isAfter(now)) timeToday else timeToday.plusDays(1)
        return Duration.between(now, next)
    }

    companion object {
        const val DAILY_WORK = "musclecheck.daily.reminder"
        const val INACTIVITY_WORK = "musclecheck.inactivity.summary"
        val INACTIVITY_FIRE_TIME: LocalTime = LocalTime.of(10, 0)
    }
}
