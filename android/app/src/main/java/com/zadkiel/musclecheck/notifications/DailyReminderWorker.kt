package com.zadkiel.musclecheck.notifications

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first

/** Fires every day at the user's chosen reminder time. */
@HiltWorker
class DailyReminderWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val prefs: UserPreferencesRepository,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        if (!prefs.notificationsEnabled.first()) return Result.success()
        ReminderNotifications.post(
            context = applicationContext,
            notificationId = ReminderNotifications.DAILY_NOTIFICATION_ID,
            title = applicationContext.getString(R.string.notification_daily_title),
            body = applicationContext.getString(R.string.notification_daily_body),
        )
        return Result.success()
    }
}
