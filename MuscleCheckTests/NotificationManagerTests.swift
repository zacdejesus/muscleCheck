//
//  NotificationManagerTests.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

struct NotificationManagerTests {

    // MARK: - Helpers

    private func makeEntry(name: String, daysAgo: [Int]) -> MuscleEntry {
        let entry = MuscleEntry(name: name)
        let calendar = Date.appCalendar
        for day in daysAgo {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
                entry.addActivityDate(date)
            }
        }
        return entry
    }

    // MARK: - daysInactive

    @Test
    func testDaysInactiveNeverTrained() {
        let entry = MuscleEntry(name: "Pecho") // no activityDates
        #expect(NotificationManager.daysInactive(for: entry) == Int.max)
    }

    @Test
    func testDaysInactiveTrainedToday() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0])
        #expect(NotificationManager.daysInactive(for: entry) == 0)
    }

    @Test
    func testDaysInactiveTrainedThreeDaysAgo() {
        let entry = makeEntry(name: "Espalda", daysAgo: [3])
        #expect(NotificationManager.daysInactive(for: entry) == 3)
    }

    @Test
    func testDaysInactiveUsesMaxDate() {
        // Multiple activity dates — should use the most recent
        let entry = makeEntry(name: "Piernas", daysAgo: [7, 3, 1])
        #expect(NotificationManager.daysInactive(for: entry) == 1)
    }

    // MARK: - MockNotificationManager protocol contract

    @Test
    func testMockRecordsScheduleDailyReminder() async {
        let mock = MockNotificationManager()
        await mock.scheduleDailyReminder(hour: 18, minute: 30)
        #expect(mock.scheduleDailyReminderCalled)
        #expect(mock.lastScheduledHour == 18)
        #expect(mock.lastScheduledMinute == 30)
    }

    @Test
    func testMockRecordsRequestAuthorization() async {
        let mock = MockNotificationManager()
        mock.shouldGrantAuthorization = false
        let granted = await mock.requestAuthorization()
        #expect(mock.requestAuthorizationCalled)
        #expect(!granted)
        #expect(!mock.isAuthorized)
    }

    @Test
    func testMockRecordsInactivitySchedule() async {
        let mock = MockNotificationManager()
        let entries = [makeEntry(name: "Pecho", daysAgo: [5])]
        await mock.scheduleInactivityReminders(for: entries)
        #expect(mock.scheduleInactivityRemindersCalled)
        #expect(mock.lastScheduledEntries?.count == 1)
    }

    @Test
    func testMockCancelDailyReminder() {
        let mock = MockNotificationManager()
        mock.cancelDailyReminder()
        #expect(mock.cancelDailyCalled)
    }

    // MARK: - Inactivity threshold

    @Test
    func testEntriesWithLessThanThreeDaysNotFlagged() {
        let entry2Days = makeEntry(name: "Pecho", daysAgo: [2])
        #expect(NotificationManager.daysInactive(for: entry2Days) < 3)
    }

    @Test
    func testEntriesWithExactlyThreeDaysAreFlagged() {
        let entry3Days = makeEntry(name: "Hombros", daysAgo: [3])
        #expect(NotificationManager.daysInactive(for: entry3Days) >= 3)
    }
}
