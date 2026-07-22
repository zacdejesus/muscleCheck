//
//  NotificationManagerTests.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

@MainActor
struct NotificationManagerTests {

    // MARK: - Helpers

    private func makeEntry(name: String, daysAgo: [Int]) -> MuscleEntry {
        let entry = MuscleEntry(name: name)
        let calendar = Date.appCalendar
        for day in daysAgo {
            if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
                entry.addSession(date)
            }
        }
        return entry
    }

    // MARK: - daysInactive

    @Test
    func testDaysInactiveNeverTrained() {
        let entry = MuscleEntry(name: "Pecho") // no sessions
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
        // Multiple sessions — should use the most recent
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

    // MARK: - inactiveEntries (summary eligibility)

    @Test
    func testInactiveEntriesExcludesNeverTrained() {
        // Regression: never-trained presets used to fire one notification each (2.1.0 spam)
        let neverTrained = MuscleEntry(name: "Yoga")
        let trained = makeEntry(name: "Pecho", daysAgo: [5])
        let result = NotificationManager.inactiveEntries(from: [neverTrained, trained])
        #expect(result.count == 1)
        #expect(result.first?.entry.name == "Pecho")
    }

    @Test
    func testInactiveEntriesExcludesRecentlyTrained() {
        let recent = makeEntry(name: "Pecho", daysAgo: [1])
        let result = NotificationManager.inactiveEntries(from: [recent])
        #expect(result.isEmpty)
    }

    @Test
    func testInactiveEntriesSortedMostInactiveFirst() {
        let a = makeEntry(name: "Pecho", daysAgo: [4])
        let b = makeEntry(name: "Espalda", daysAgo: [9])
        let c = makeEntry(name: "Piernas", daysAgo: [6])
        let result = NotificationManager.inactiveEntries(from: [a, b, c])
        #expect(result.map { $0.entry.name } == ["Espalda", "Piernas", "Pecho"])
    }

    // MARK: - inactivityBody (single summary notification)

    @Test
    func testInactivityBodyNilWhenNothingEligible() {
        #expect(NotificationManager.inactivityBody(for: []) == nil)
    }

    @Test
    func testInactivityBodySingleMentionsNameAndDays() {
        let inactive = NotificationManager.inactiveEntries(from: [makeEntry(name: "Espalda", daysAgo: [5])])
        let body = NotificationManager.inactivityBody(for: inactive)
        #expect(body?.contains("Espalda") == true)
        #expect(body?.contains("5") == true)
    }

    @Test
    func testInactivityBodyMultipleMentionsCountAndCapsNamesAtThree() {
        let entries = [
            makeEntry(name: "Pecho", daysAgo: [9]),
            makeEntry(name: "Espalda", daysAgo: [8]),
            makeEntry(name: "Piernas", daysAgo: [7]),
            makeEntry(name: "Hombros", daysAgo: [6]),
        ]
        let inactive = NotificationManager.inactiveEntries(from: entries)
        let body = NotificationManager.inactivityBody(for: inactive)
        #expect(body?.contains("4") == true)
        #expect(body?.contains("Pecho") == true)
        #expect(body?.contains("Espalda") == true)
        #expect(body?.contains("Piernas") == true)
        #expect(body?.contains("Hombros") == false) // capped at 3 names
        #expect(body?.contains("…") == true)
    }
}
