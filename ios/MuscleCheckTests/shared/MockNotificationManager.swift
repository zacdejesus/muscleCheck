//
//  MockNotificationManager.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation
@testable import MuscleCheck

final class MockNotificationManager: NotificationManagerProtocol {
    var isAuthorized: Bool = true

    // Recorded calls
    var requestAuthorizationCalled = false
    var scheduleDailyReminderCalled = false
    var scheduleInactivityRemindersCalled = false
    var cancelAllCalled = false
    var cancelDailyCalled = false

    var lastScheduledHour: Int?
    var lastScheduledMinute: Int?
    var lastScheduledEntries: [MuscleEntry]?

    // Control behaviour
    var shouldGrantAuthorization = true

    func requestAuthorization() async -> Bool {
        requestAuthorizationCalled = true
        isAuthorized = shouldGrantAuthorization
        return shouldGrantAuthorization
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        scheduleDailyReminderCalled = true
        lastScheduledHour = hour
        lastScheduledMinute = minute
    }

    func scheduleInactivityReminders(for entries: [MuscleEntry]) async {
        scheduleInactivityRemindersCalled = true
        lastScheduledEntries = entries
    }

    func cancelAllNotifications() {
        cancelAllCalled = true
    }

    func cancelDailyReminder() {
        cancelDailyCalled = true
    }
}
