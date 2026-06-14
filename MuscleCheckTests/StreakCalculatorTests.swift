//
//  StreakCalculatorTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

struct StreakCalculatorTests {

    /// Adds a session N weeks ago (each entry in `weeksAgo` lands in a distinct calendar week).
    private func makeEntry(name: String, weeksAgo: [Int]) -> MuscleEntry {
        let entry = MuscleEntry(name: name)
        let calendar = Date.appCalendar
        for week in weeksAgo {
            if let date = calendar.date(byAdding: .weekOfYear, value: -week, to: Date()) {
                entry.addSession(date)
            }
        }
        return entry
    }

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

    // MARK: - Current weekly streak

    @Test
    func testNoEntriesReturnsZeroStreak() {
        #expect(StreakCalculator.currentStreak(from: []) == 0)
        #expect(StreakCalculator.maxStreak(from: []) == 0)
    }

    @Test
    func testTrainedThisWeekStreakIsOne() {
        let entry = makeEntry(name: "Pecho", weeksAgo: [0])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 1)
    }

    @Test
    func testThisAndLastWeekStreakIsTwo() {
        let entry = makeEntry(name: "Pecho", weeksAgo: [0, 1])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 2)
    }

    @Test
    func testLastWeekOnlyStaysAliveByGrace() {
        // Nothing this week yet, but trained last week → the in-progress week doesn't break it.
        let entry = makeEntry(name: "Pecho", weeksAgo: [1])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 1)
    }

    @Test
    func testTwoWeeksAgoIsDead() {
        // Neither this week nor last week → streak is 0.
        let entry = makeEntry(name: "Pecho", weeksAgo: [2])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 0)
    }

    @Test
    func testGapBreaksWeeklyStreak() {
        // This week + two weeks ago, but last week skipped → current run is just this week.
        let entry = makeEntry(name: "Pecho", weeksAgo: [0, 2])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 1)
    }

    @Test
    func testMultipleSessionsSameWeekCountAsOneWeek() {
        let entry1 = makeEntry(name: "Pecho", weeksAgo: [0])
        let entry2 = makeEntry(name: "Espalda", weeksAgo: [0])
        #expect(StreakCalculator.currentStreak(from: [entry1, entry2]) == 1)
    }

    // MARK: - Max weekly streak

    @Test
    func testMaxWeeklyStreakAcrossMultipleEntries() {
        let entry1 = makeEntry(name: "Pecho", weeksAgo: [0, 1, 2])       // run of 3
        let entry2 = makeEntry(name: "Espalda", weeksAgo: [5, 6, 7, 8])  // older run of 4
        #expect(StreakCalculator.maxStreak(from: [entry1, entry2]) == 4)
    }

    // MARK: - Helpers that didn't change (day-level)

    @Test
    func testDeduplicatesDaysAcrossEntries() {
        let entry1 = makeEntry(name: "Pecho", daysAgo: [0])
        let entry2 = makeEntry(name: "Espalda", daysAgo: [0])
        let days = StreakCalculator.uniqueTrainingDays(from: [entry1, entry2])
        #expect(days.count == 1)
    }

    @Test
    func testLastTrainedDateIsToday() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0])
        guard let last = StreakCalculator.lastTrainedDate(from: [entry]) else {
            #expect(Bool(false), "lastTrainedDate should not be nil")
            return
        }
        #expect(Date.appCalendar.isDateInToday(last))
    }
}
