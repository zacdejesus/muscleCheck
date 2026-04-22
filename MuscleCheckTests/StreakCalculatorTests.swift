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

    @Test
    func testNoEntriesReturnsZeroStreak() {
        #expect(StreakCalculator.currentStreak(from: []) == 0)
        #expect(StreakCalculator.maxStreak(from: []) == 0)
    }

    @Test
    func testTrainedTodayStreakIsOne() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 1)
    }

    @Test
    func testTrainedTodayAndYesterdayStreakIsTwo() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0, 1])
        #expect(StreakCalculator.currentStreak(from: [entry]) == 2)
    }

    @Test
    func testGapBreaksStreak() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0, 2]) // gap on day 1
        #expect(StreakCalculator.currentStreak(from: [entry]) == 1)
    }

    @Test
    func testStreakDeadIfLastTrainedMoreThanYesterdayAgo() {
        let entry = makeEntry(name: "Pecho", daysAgo: [2, 3, 4]) // last was 2 days ago
        #expect(StreakCalculator.currentStreak(from: [entry]) == 0)
    }

    @Test
    func testMaxStreakAcrossMultipleEntries() {
        let entry1 = makeEntry(name: "Pecho", daysAgo: [0, 1, 2])
        let entry2 = makeEntry(name: "Espalda", daysAgo: [5, 6, 7, 8]) // older run of 4
        #expect(StreakCalculator.maxStreak(from: [entry1, entry2]) == 4)
    }

    @Test
    func testDeduplicatesDaysAcrossEntries() {
        // Both entries trained same day - should count as 1 unique day
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
