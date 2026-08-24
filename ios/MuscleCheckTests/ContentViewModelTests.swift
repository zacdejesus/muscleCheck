//
//  ContentViewModelTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 10/06/2025.
//


import Testing
@testable import MuscleCheck
import SwiftData
import Foundation

// Serialized: these tests contend on shared UserDefaults flags (onboarding/seed state).
@Suite(.serialized)
struct ContentViewModelTests {

    @MainActor @Test
    func testInsertDefaultMuscleEntriesOnlyOnce() async {
        let context = MockContext()
        // Fallback seed path: onboarded but never seeded.
        UserDefaultsManager.shared.hasCompletedOnboarding = true
        UserDefaultsManager.shared.defaultEntriesCreated = false

        let viewModel = ContentViewModel()
        await viewModel.setup(context: context, entries: [])

        #expect(context.inserted.count > 0)
        #expect(UserDefaultsManager.shared.defaultEntriesCreated == true)
    }

    @MainActor @Test
    func testSeedSkippedWhileOnboardingPending() async {
        let context = MockContext()
        // New install: onboarding decides the seed, so setup must not insert anything.
        UserDefaultsManager.shared.hasCompletedOnboarding = false
        UserDefaultsManager.shared.defaultEntriesCreated = false

        let viewModel = ContentViewModel()
        await viewModel.setup(context: context, entries: [])

        #expect(context.inserted.isEmpty)
        #expect(UserDefaultsManager.shared.defaultEntriesCreated == false)
    }

    @MainActor @Test
    func testToggleActivityAddsAndRemovesSession() async {
        let entry = MuscleEntry(name: "Piernas")
        let viewModel = ContentViewModel()
        await viewModel.setup(context: MockContext(), entries: [entry])

        viewModel.toggleActivity(for: entry)
        #expect(entry.isChecked == true)
        #expect(entry.sessions.contains(where: { Calendar.current.isDateInToday($0.date) }))

        viewModel.toggleActivity(for: entry)
        #expect(entry.isChecked == false)
        #expect(entry.sessions.isEmpty)
    }

    @MainActor @Test
    func testSaveSessionPersistsAndMarksChecked() async {
        let entry = MuscleEntry(name: "Pecho")
        let viewModel = ContentViewModel()
        await viewModel.setup(context: MockContext(), entries: [entry])

        viewModel.saveSession(SessionInput(weightKg: 80.0, sets: 4, reps: 10), for: entry)

        #expect(entry.isChecked == true)
        #expect(entry.lastWeight == 80.0)
        #expect(entry.lastSets == 4)
        #expect(entry.lastReps == 10)
        #expect(entry.sessions.count == 1)
    }

    @MainActor @Test
    func testSaveSessionPersistsDurationAndDistance() async {
        let entry = MuscleEntry(name: "Correr", category: "running")
        let viewModel = ContentViewModel()
        await viewModel.setup(context: MockContext(), entries: [entry])

        viewModel.saveSession(SessionInput(durationSeconds: 1800, distanceMeters: 5000), for: entry)

        #expect(entry.isChecked == true)
        #expect(entry.lastDurationSeconds == 1800)
        #expect(entry.lastDistanceMeters == 5000)
        #expect(entry.sessions.count == 1)
    }

    /// Regression (tech debt item 4): trained Monday, un-checking on Wednesday.
    /// Before the refactor this left the Monday session alive while the flag went
    /// false — the home said "not trained" while streak, stats and history still
    /// counted it. Un-checking now clears the whole week, so every reader agrees.
    @MainActor @Test
    func testToggleActivityUnchecksEvenWhenTheSessionIsFromAnotherDay() async {
        let cal = Date.appCalendar
        let monday = Date().startOfWeek()!
        let earlierThisWeek = cal.isDateInToday(monday) ? cal.date(byAdding: .day, value: 1, to: monday)! : monday

        let entry = MuscleEntry(name: "Piernas")
        entry.addSession(earlierThisWeek)

        let viewModel = ContentViewModel()
        await viewModel.setup(context: MockContext(), entries: [entry])
        #expect(entry.isChecked == true)

        viewModel.toggleActivity(for: entry)

        #expect(entry.isChecked == false)
        #expect(entry.sessions.isEmpty)
    }
}
