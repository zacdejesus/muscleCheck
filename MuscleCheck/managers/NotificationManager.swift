//
//  NotificationManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject, NotificationManagerProtocol {
    static let shared = NotificationManager()
    private init() {}

    @Published private(set) var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderID = "musclecheck.daily.reminder"
    private let inactivityPrefix = "musclecheck.inactivity."

    // MARK: - Authorization

    /// Syncs `isAuthorized` with the current system setting (call on app launch).
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    // MARK: - Daily reminder

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        cancelDailyReminder()
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_daily_title", comment: "")
        content.body = NSLocalizedString("notification_daily_body", comment: "")
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    // MARK: - Inactivity reminders

    func scheduleInactivityReminders(for entries: [MuscleEntry]) async {
        // Remove previous inactivity notifications
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(inactivityPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)
        guard isAuthorized else { return }

        let calendar = Date.appCalendar
        let today = calendar.startOfDay(for: Date())

        for entry in entries {
            let daysSince = Self.daysInactive(for: entry, today: today)
            guard daysSince >= 3 else { continue }

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification_inactivity_title", comment: "")
            content.body = String(
                format: NSLocalizedString("notification_inactivity_body", comment: ""),
                entry.name,
                daysSince
            )
            content.sound = .default

            // Fire tomorrow at 10 AM (one-shot)
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { continue }
            var fireComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            fireComponents.hour = 10
            fireComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
            let id = "\(inactivityPrefix)\(entry.id)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    // MARK: - Cancel all

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Pure helper (internal for testing)

    /// Returns the number of full days since the entry was last trained (0 if never trained → Int.max).
    static func daysInactive(for entry: MuscleEntry, today: Date = Date()) -> Int {
        let calendar = Date.appCalendar
        let todayStart = calendar.startOfDay(for: today)
        guard let lastDate = entry.activityDates.max() else { return Int.max }
        let lastDay = calendar.startOfDay(for: lastDate)
        let components = calendar.dateComponents([.day], from: lastDay, to: todayStart)
        return max(0, components.day ?? 0)
    }
}
