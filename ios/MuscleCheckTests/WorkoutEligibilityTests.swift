//
//  WorkoutEligibilityTests.swift
//  MuscleCheckTests
//
//  Covers the pure rotation/eligibility + index-mapping logic for the AI Coach
//  (Feature 12). This is where the real "intelligence" lives — the model only
//  picks from what these functions hand it — so it's worth covering thoroughly.
//

import Testing
@testable import MuscleCheck
import Foundation

struct WorkoutEligibilityTests {

    private let today = Date()

    private func makeEntry(_ name: String,
                           category: ActivityCategory = .gym,
                           daysAgo: [Int] = []) -> MuscleEntry {
        let entry = MuscleEntry(name: name, category: category.rawValue)
        let calendar = Date.appCalendar
        for day in daysAgo {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                entry.addSession(date)
            }
        }
        return entry
    }

    private func names(_ entries: [MuscleEntry]) -> [String] { entries.map(\.name) }

    // MARK: - eligibleGymGroups

    @Test
    func onlyGymGroupsAreConsidered() {
        let entries = [
            makeEntry("Pecho", category: .gym),
            makeEntry("Vinyasa", category: .yoga),
            makeEntry("Running", category: .cardio),
            makeEntry("Espalda", category: .gym)
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, today: today)
        #expect(Set(names(eligible)) == ["Pecho", "Espalda"])
    }

    @Test
    func neverTrainedGroupsAreEligible() {
        let entries = [makeEntry("Pecho"), makeEntry("Espalda")]
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, today: today)
        #expect(Set(names(eligible)) == ["Pecho", "Espalda"])
    }

    @Test
    func groupsTrainedTodayOrYesterdayAreNotEligible() {
        // restDays = 1 → today (0) and yesterday (1) excluded, 2+ days eligible.
        let entries = [
            makeEntry("Pecho", daysAgo: [0]),   // today → out
            makeEntry("Espalda", daysAgo: [1]), // yesterday → out
            makeEntry("Piernas", daysAgo: [2]), // 2 days ago → eligible
            makeEntry("Biceps", daysAgo: [5])   // eligible
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, today: today)
        #expect(Set(names(eligible)) == ["Piernas", "Biceps"])
    }

    @Test
    func restDaysParameterIsRespected() {
        let entries = [
            makeEntry("Pecho", daysAgo: [3]),    // exactly 3 → not > 3 → out
            makeEntry("Espalda", daysAgo: [4]),  // eligible
            makeEntry("Piernas", daysAgo: [5])   // eligible
        ]
        // restDays = 3 → only > 3 days rested is eligible. Two qualify, so no fallback.
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, restDays: 3, today: today)
        #expect(Set(names(eligible)) == ["Espalda", "Piernas"])
    }

    @Test
    func excludedGroupsAreDropped() {
        let entries = [
            makeEntry("Pecho", daysAgo: [5]),
            makeEntry("Espalda", daysAgo: [5]),
            makeEntry("Piernas", daysAgo: [5])
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(
            from: entries, excluding: ["Pecho"], today: today
        )
        #expect(Set(names(eligible)) == ["Espalda", "Piernas"])
    }

    @Test
    func fallsBackToAllGymGroupsWhenFewerThanTwoEligible() {
        // One eligible (never trained) + two trained today → fallback to all 3,
        // most-rested first (never-trained leads).
        let entries = [
            makeEntry("Pecho", daysAgo: [0]),
            makeEntry("Espalda"),            // never trained → most rested
            makeEntry("Piernas", daysAgo: [0])
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, today: today)
        #expect(eligible.count == 3)
        #expect(eligible.first?.name == "Espalda")
    }

    @Test
    func fallbackIgnoresExclusionToGuaranteeAPair() {
        // All rested, but exclusion leaves only one → fallback returns all 3
        // (including the excluded ones) so the model still has a pair.
        let entries = [
            makeEntry("Pecho", daysAgo: [5]),
            makeEntry("Espalda", daysAgo: [5]),
            makeEntry("Piernas", daysAgo: [5])
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(
            from: entries, excluding: ["Pecho", "Espalda"], today: today
        )
        #expect(eligible.count == 3)
    }

    @Test
    func deletedGroupsAreExcludedFromFallbackToo() {
        // No eligible gym groups at all → fallback should still only return gym, non-deleted.
        let entries = [
            makeEntry("Yoga", category: .yoga, daysAgo: [0])
        ]
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, today: today)
        #expect(eligible.isEmpty)
    }

    // MARK: - resolveBlocks

    private func gymGroups(_ names: [String]) -> [MuscleEntry] {
        names.map { makeEntry($0) }
    }

    @Test
    func resolveBlocksMapsIndicesToNames() {
        let eligible = gymGroups(["Espalda", "Biceps", "Piernas"])
        let raw = [(index: 0, exercises: ["Remo", "Dominadas", "Jalón"]),
                   (index: 1, exercises: ["Curl", "Martillo", "Concentrado"])]
        let blocks = WorkoutEligibility.resolveBlocks(rawBlocks: raw, eligible: eligible)
        #expect(blocks.map(\.groupName) == ["Espalda", "Biceps"])
        #expect(blocks[0].exercises == ["Remo", "Dominadas", "Jalón"])
    }

    @Test
    func resolveBlocksDropsOutOfRangeIndices() {
        let eligible = gymGroups(["Espalda", "Biceps"])
        let raw = [(index: 5, exercises: ["x"]),
                   (index: 1, exercises: ["Curl"])]
        let blocks = WorkoutEligibility.resolveBlocks(rawBlocks: raw, eligible: eligible)
        #expect(blocks.map(\.groupName) == ["Biceps"])
    }

    @Test
    func resolveBlocksDeduplicatesRepeatedIndices() {
        let eligible = gymGroups(["Espalda", "Biceps"])
        let raw = [(index: 0, exercises: ["Remo"]),
                   (index: 0, exercises: ["Dominadas"])]
        let blocks = WorkoutEligibility.resolveBlocks(rawBlocks: raw, eligible: eligible)
        #expect(blocks.count == 1)
        #expect(blocks[0].groupName == "Espalda")
    }

    @Test
    func resolveBlocksCapsAtTwoBlocksAndThreeExercises() {
        let eligible = gymGroups(["A", "B", "C"])
        let raw = [(index: 0, exercises: ["1", "2", "3", "4"]),
                   (index: 1, exercises: ["1"]),
                   (index: 2, exercises: ["1"])]
        let blocks = WorkoutEligibility.resolveBlocks(rawBlocks: raw, eligible: eligible)
        #expect(blocks.count == 2)
        #expect(blocks[0].exercises == ["1", "2", "3"])
    }

    @Test
    func resolveBlocksEmptyInputReturnsEmpty() {
        let blocks = WorkoutEligibility.resolveBlocks(rawBlocks: [], eligible: gymGroups(["A"]))
        #expect(blocks.isEmpty)
    }
}
