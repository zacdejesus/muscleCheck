//
//  MuscleEntryTests.swift
//  MuscleCheckTests
//

import Testing
@testable import MuscleCheck
import Foundation

struct MuscleEntryTests {

    // MARK: - addSession

    @Test
    func testAddSessionAppendsForNewDay() {
        let entry = MuscleEntry(name: "Pecho")
        entry.addSession(Date())
        #expect(entry.sessions.count == 1)
    }

    @Test
    func testAddSessionDedupesSameDay() {
        let entry = MuscleEntry(name: "Pecho")
        let today = Date()
        entry.addSession(today)
        entry.addSession(today)
        entry.addSession(today)
        #expect(entry.sessions.count == 1)
    }

    @Test
    func testAddSessionDifferentDaysAccumulate() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!

        entry.addSession(today)
        entry.addSession(yesterday)
        entry.addSession(twoDaysAgo)
        #expect(entry.sessions.count == 3)
    }

    @Test
    func testAddSessionInheritsLastWeightWhenNotProvided() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!

        entry.addSession(yesterday, weight: 80.0)
        entry.addSession(Date()) // no weight provided

        let todays = entry.sessions.first { cal.isDateInToday($0.date) }
        #expect(todays?.weight == 80.0)
    }

    @Test
    func testAddSessionExplicitWeightOverridesLast() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!

        entry.addSession(yesterday, weight: 80.0)
        entry.addSession(Date(), weight: 100.0)

        let todays = entry.sessions.first { cal.isDateInToday($0.date) }
        #expect(todays?.weight == 100.0)
    }

    // MARK: - removeSession

    @Test
    func testRemoveSessionDeletesMatchingDay() {
        let entry = MuscleEntry(name: "Pecho")
        entry.addSession(Date())
        entry.removeSession(matching: Date())
        #expect(entry.sessions.isEmpty)
    }

    @Test
    func testRemoveSessionDoesNotAffectOtherDays() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!

        entry.addSession(yesterday)
        entry.addSession(Date())
        entry.removeSession(matching: Date())

        #expect(entry.sessions.count == 1)
        #expect(cal.isDate(entry.sessions[0].date, inSameDayAs: yesterday))
    }

    // MARK: - setTodaysWeight

    @Test
    func testSetTodaysWeightCreatesSessionWhenNoneExists() {
        let entry = MuscleEntry(name: "Pecho")
        entry.setTodaysWeight(80.0)

        #expect(entry.sessions.count == 1)
        #expect(entry.lastWeight == 80.0)
        #expect(entry.isChecked == true)
    }

    @Test
    func testSetTodaysWeightUpdatesExistingTodaySession() {
        let entry = MuscleEntry(name: "Pecho")
        entry.addSession(Date(), weight: 80.0)
        entry.setTodaysWeight(100.0)

        #expect(entry.sessions.count == 1)
        #expect(entry.lastWeight == 100.0)
    }

    @Test
    func testSetTodaysWeightMarksIsChecked() {
        let entry = MuscleEntry(name: "Pecho")
        entry.isChecked = false
        entry.setTodaysWeight(80.0)
        #expect(entry.isChecked == true)
    }

    @Test
    func testSetTodaysWeightWithNilStoresNil() {
        let entry = MuscleEntry(name: "Pecho")
        entry.setTodaysWeight(nil)
        #expect(entry.sessions.count == 1)
        #expect(entry.sessions[0].weight == nil)
    }

    // MARK: - lastWeight

    @Test
    func testLastWeightIsNilWhenNoSessions() {
        let entry = MuscleEntry(name: "Pecho")
        #expect(entry.lastWeight == nil)
    }

    @Test
    func testLastWeightReturnsMostRecentSessionWithWeight() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date())!
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!

        entry.addSession(twoDaysAgo, weight: 70.0)
        entry.addSession(yesterday, weight: 75.0)
        entry.addSession(Date(), weight: 80.0)

        #expect(entry.lastWeight == 80.0)
    }

    @Test
    func testLastWeightSkipsSessionsWithoutWeight() {
        let entry = MuscleEntry(name: "Pecho")
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!

        entry.addSession(yesterday, weight: 80.0)
        // addSession would inherit lastWeight, so use setTodaysWeight(nil) to force nil
        entry.setTodaysWeight(nil)

        #expect(entry.lastWeight == 80.0)
    }

    // MARK: - formattedLastWeight

    @MainActor @Test
    func testFormattedLastWeightNilWhenNoWeight() {
        let entry = MuscleEntry(name: "Pecho")
        #expect(entry.formattedLastWeight == nil)
    }

    @MainActor @Test
    func testFormattedLastWeightUsesKgWhenUnitIsKg() {
        UserDefaultsManager.shared.weightUnit = .kg
        let entry = MuscleEntry(name: "Pecho")
        entry.addSession(Date(), weight: 80.0)
        #expect(entry.formattedLastWeight == "80 kg")
    }

    @MainActor @Test
    func testFormattedLastWeightDropsTrailingZeros() {
        UserDefaultsManager.shared.weightUnit = .kg
        let entry = MuscleEntry(name: "Pecho")
        entry.addSession(Date(), weight: 80.5)
        #expect(entry.formattedLastWeight == "80 kg")
    }
}
