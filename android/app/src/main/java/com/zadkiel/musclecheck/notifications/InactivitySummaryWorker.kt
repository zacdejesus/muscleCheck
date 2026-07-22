package com.zadkiel.musclecheck.notifications

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.prefs.UserPreferencesRepository
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.InactivityCalculator
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first

/**
 * One-shot summary of neglected activities. Unlike iOS (which snapshots the entries when
 * scheduling), this computes inactivity at fire time, so the message is never stale.
 */
@HiltWorker
class InactivitySummaryWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val prefs: UserPreferencesRepository,
    private val repository: MuscleRepository,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        if (!prefs.notificationsEnabled.first()) return Result.success()

        val entries = repository.entries.first()
        val inactive = InactivityCalculator.inactiveEntries(entries)
        val summary = InactivityCalculator.summary(inactive) ?: return Result.success()

        val body = if (summary.count == 1) {
            applicationContext.getString(
                R.string.notification_inactivity_body, summary.firstName, summary.firstDays,
            )
        } else {
            applicationContext.getString(
                R.string.notification_inactivity_body_multiple, summary.count, summary.joinedNames,
            )
        }
        ReminderNotifications.post(
            context = applicationContext,
            notificationId = ReminderNotifications.INACTIVITY_NOTIFICATION_ID,
            title = applicationContext.getString(R.string.notification_inactivity_title),
            body = body,
        )
        return Result.success()
    }
}
