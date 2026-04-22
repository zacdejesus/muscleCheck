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

    /// Schedules one-time inactivity reminders for muscles not trained in 3+ days.
    func scheduleInactivityReminders(for entries: [MuscleEntry]) async

    /// Cancels all pending notifications.
    func cancelAllNotifications()

    /// Cancels only the daily reminder.
    func cancelDailyReminder()
}
