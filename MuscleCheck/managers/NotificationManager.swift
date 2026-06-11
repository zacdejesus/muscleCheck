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
    // Shares the prefix so the cleanup pass also removes legacy per-entry reminders
    // scheduled by versions ≤ 2.1.0.
    private let inactivitySummaryID = "musclecheck.inactivity.summary"

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

        let inactive = Self.inactiveEntries(from: entries, today: today)
        guard let body = Self.inactivityBody(for: inactive) else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_inactivity_title", comment: "")
        content.body = body
        content.sound = .default

        // Fire tomorrow at 10 AM (one-shot)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        var fireComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        fireComponents.hour = 10
        fireComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: inactivitySummaryID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Cancel all

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Pure helpers (internal for testing)

    /// Returns the number of full days since the entry was last trained (0 if never trained → Int.max).
    static func daysInactive(for entry: MuscleEntry, today: Date = Date()) -> Int {
        let calendar = Date.appCalendar
        let todayStart = calendar.startOfDay(for: today)
        guard let lastDate = entry.sessions.map(\.date).max() else { return Int.max }
        let lastDay = calendar.startOfDay(for: lastDate)
        let components = calendar.dateComponents([.day], from: lastDay, to: todayStart)
        return max(0, components.day ?? 0)
    }

    /// Entries eligible for an inactivity reminder, most-inactive first.
    /// Never-trained entries (`Int.max`) are excluded — nagging about an activity
    /// the user hasn't even started is what caused the 2.1.0 notification spam.
    static func inactiveEntries(from entries: [MuscleEntry], today: Date = Date()) -> [(entry: MuscleEntry, days: Int)] {
        entries
            .map { (entry: $0, days: daysInactive(for: $0, today: today)) }
            .filter { $0.days >= 3 && $0.days != Int.max }
            .sorted { $0.days > $1.days }
    }

    /// Single summary body covering every inactive entry, or nil when there's nothing to say.
    static func inactivityBody(for inactive: [(entry: MuscleEntry, days: Int)]) -> String? {
        guard let first = inactive.first else { return nil }
        if inactive.count == 1 {
            return String(
                format: NSLocalizedString("notification_inactivity_body", comment: ""),
                first.entry.name,
                first.days
            )
        }
        let names = inactive.prefix(3).map { $0.entry.name }.joined(separator: ", ")
        let suffix = inactive.count > 3 ? "…" : ""
        return String(
            format: NSLocalizedString("notification_inactivity_body_multiple", comment: ""),
            inactive.count,
            names + suffix
        )
    }
}
