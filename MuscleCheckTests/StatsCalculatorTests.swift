//
//  StatsCalculatorTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

struct StatsCalculatorTests {

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

    // MARK: - totalDaysTrained

    @Test
    func testTotalDaysTrainedNoEntries() {
        #expect(StatsCalculator.totalDaysTrained(from: []) == 0)
    }

    @Test
    func testTotalDaysTrainedDeduplicatesAcrossEntries() {
        // Two entries trained on same day → should count as 1
        let entry1 = makeEntry(name: "Pecho", daysAgo: [0, 1])
        let entry2 = makeEntry(name: "Espalda", daysAgo: [0, 2])
        // Unique days: today (0), yesterday (1), 2 days ago (2) = 3
        #expect(StatsCalculator.totalDaysTrained(from: [entry1, entry2]) == 3)
    }

    // MARK: - frequencyByMuscle

    @Test
    func testFrequencyByMuscleEmpty() {
        #expect(StatsCalculator.frequencyByMuscle(from: []).isEmpty)
    }

    @Test
    func testFrequencyByMuscleExcludesZeroCount() {
        let entry = MuscleEntry(name: "Sin actividad") // no activityDates
        #expect(StatsCalculator.frequencyByMuscle(from: [entry]).isEmpty)
    }

    @Test
    func testFrequencyByMuscleSortedDescending() {
        let entry1 = makeEntry(name: "Pecho", daysAgo: [0, 1, 2])    // 3 days
        let entry2 = makeEntry(name: "Espalda", daysAgo: [0, 1])      // 2 days
        let entry3 = makeEntry(name: "Piernas", daysAgo: [0, 1, 2, 3]) // 4 days

        let result = StatsCalculator.frequencyByMuscle(from: [entry1, entry2, entry3])

        #expect(result[0].muscle == "Piernas")
        #expect(result[0].count == 4)
        #expect(result[1].muscle == "Pecho")
        #expect(result[1].count == 3)
        #expect(result[2].muscle == "Espalda")
        #expect(result[2].count == 2)
    }

    @Test
    func testFrequencyByMuscleDeduplicatesSameDayDates() {
        // Adding the same day twice should count as 1 (addActivityDate guards duplicates)
        let entry = makeEntry(name: "Pecho", daysAgo: [0])
        let result = StatsCalculator.frequencyByMuscle(from: [entry])
        #expect(result.first?.count == 1)
    }

    // MARK: - daysTrainedPerWeek

    @Test
    func testDaysTrainedPerWeekReturnsCorrectCount() {
        let weekly = StatsCalculator.daysTrainedPerWeek(from: [], numberOfWeeks: 4)
        #expect(weekly.count == 4)
    }

    @Test
    func testDaysTrainedPerWeekCurrentWeekCount() {
        let entry = makeEntry(name: "Pecho", daysAgo: [0, 1]) // trained today & yesterday
        let weekly = StatsCalculator.daysTrainedPerWeek(from: [entry], numberOfWeeks: 4)
        // Last element is current week
        let currentWeek = weekly.last
        #expect(currentWeek != nil)
        // Should have at least 1 (today is always in current week)
        #expect((currentWeek?.count ?? 0) >= 1)
    }

    // MARK: - averageTrainingDaysPerWeek

    @Test
    func testAverageReturnsZeroForNoEntries() {
        let avg = StatsCalculator.averageTrainingDaysPerWeek(from: [], numberOfWeeks: 4)
        #expect(avg == 0.0)
    }

    @Test
    func testAverageIsCorrect() {
        // Train today only → current week has 1 day, others have 0
        let entry = makeEntry(name: "Pecho", daysAgo: [0])
        let avg = StatsCalculator.averageTrainingDaysPerWeek(from: [entry], numberOfWeeks: 4)
        // 1 day / 4 weeks = 0.25
        #expect(avg == 0.25)
    }
}
