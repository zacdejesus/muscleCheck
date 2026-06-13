//
//  NotificationManagerProtocol.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation

@MainActor
protocol NotificationManagerProtocol: AnyObject {
    /// Whether the user has granted notification permission.
    var isAuthorized: Bool { get }

    /// Requests notification authorization from the system. Returns true if granted.
    func requestAuthorization() async -> Bool

    /// Schedules (or replaces) the daily reminder at the given hour/minute.
    func scheduleDailyReminder(hour: Int, minute: Int) async

    /// Schedules a single one-time reminder summarizing activities not trained in 3+ days.
    /// Never-trained entries are ignored.
    func scheduleInactivityReminders(for entries: [MuscleEntry]) async

    /// Cancels all pending notifications.
    func cancelAllNotifications()

    /// Cancels only the daily reminder.
    func cancelDailyReminder()
}
