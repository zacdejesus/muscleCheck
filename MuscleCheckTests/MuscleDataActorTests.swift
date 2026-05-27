//
//  MuscleDataActorTests.swift
//  MuscleCheck
//
//  Covers the App Intents / Siri data path (separate from the UI view models).
//  Uses an in-memory ModelContainer so the actor reads/writes a real SwiftData store.
//

import Testing
@testable import MuscleCheck
import SwiftData
import Foundation

@MainActor
struct MuscleDataActorTests {

    /// Builds an in-memory container seeded with the given muscle entries.
    /// `daysAgo` adds a session that many days before today for each value.
    private func makeContainer(_ entries: [(name: String, daysAgo: [Int])]) throws -> ModelContainer {
        let container = try ModelContainer(
            for: MuscleEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        let cal = Date.appCalendar
        for spec in entries {
            let entry = MuscleEntry(name: spec.name)
            for day in spec.daysAgo {
                if let d = cal.date(byAdding: .day, value: -day, to: Date()) {
                    entry.addSession(d)
                }
            }
            ctx.insert(entry)
        }
        try ctx.save()
        return container
    }

    @Test
    func testFetchAllMuscleNamesIsSortedAndDeduplicated() async throws {
        let container = try makeContainer([
            (name: "Pecho", daysAgo: []),
            (name: "Espalda", daysAgo: []),
            (name: "Pecho", daysAgo: [])
        ])
        let actor = MuscleDataActor(modelContainer: container)
        let names = try await actor.fetchAllMuscleNames()
        #expect(names == ["Espalda", "Pecho"])
    }

    @Test
    func testLogMuscleMarksItTrainedThisWeek() async throws {
        let container = try makeContainer([(name: "Pecho", daysAgo: [])])
        let actor = MuscleDataActor(modelContainer: container)

        let before = try await actor.getWeeklyProgress()
        #expect(before.isEmpty)

        _ = try await actor.logMuscle(named: "Pecho")

        let after = try await actor.getWeeklyProgress()
        #expect(after == ["Pecho"])
    }

    @Test
    func testLogUnknownMuscleDoesNotChangeProgress() async throws {
        let container = try makeContainer([(name: "Pecho", daysAgo: [])])
        let actor = MuscleDataActor(modelContainer: container)

        let message = try await actor.logMuscle(named: "NoExiste")
        #expect(!message.isEmpty)

        let progress = try await actor.getWeeklyProgress()
        #expect(progress.isEmpty)
    }

    @Test
    func testGetWeeklyProgressExcludesOlderSessions() async throws {
        let container = try makeContainer([
            (name: "Pecho", daysAgo: [0]),    // trained today -> this week
            (name: "Espalda", daysAgo: [30])  // trained a month ago -> excluded
        ])
        let actor = MuscleDataActor(modelContainer: container)
        let progress = try await actor.getWeeklyProgress()
        #expect(progress == ["Pecho"])
    }

    @Test
    func testGetWeeklyProgressEmptyWhenNothingTrained() async throws {
        let container = try makeContainer([(name: "Pecho", daysAgo: [])])
        let actor = MuscleDataActor(modelContainer: container)
        let progress = try await actor.getWeeklyProgress()
        #expect(progress.isEmpty)
    }
}
