//
//  ExerciseTests.swift
//  MuscleCheckTests — Feature: exercises inside a group (Fase 2)
//
//  Exercise is an inline Codable nested on MuscleEntry.exercises. These pin its
//  round-trip and value accessors. The STORE-level upgrade safety (existing
//  installs opening the new schema without a wipe) was verified end-to-end on a
//  simulator: a v1 store opened by the v2 build kept all entries.
//

import Testing
@testable import MuscleCheck
import Foundation

struct ExerciseTests {

    @Test
    func roundTripPreservesFields() throws {
        let original = Exercise(
            name: "Peso muerto",
            icon: "figure.strengthtraining.traditional",
            metric: .strength,
            sessions: [WorkoutSession(weight: 100, sets: 3, reps: 8, date: Date())]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Exercise.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == "Peso muerto")
        #expect(decoded.metric == .strength)
        #expect(decoded.sessions.count == 1)
        #expect(decoded.lastWeight == 100)
    }

    @Test
    func eachExerciseKeepsItsOwnMetric() {
        let deadlift = Exercise(name: "Peso muerto", metric: .strength)
        let plank = Exercise(name: "Plancha", metric: .duration)
        #expect(deadlift.metric == .strength)
        #expect(plank.metric == .duration)
    }

    @Test
    func lastValuesLookBackAcrossSessions() {
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let ex = Exercise(name: "Hip thrust", metric: .strength, sessions: [
            WorkoutSession(weight: 80, sets: 4, reps: 10, date: yesterday),
            WorkoutSession(weight: nil, date: Date()),
        ])
        #expect(ex.lastWeight == 80)   // most recent session WITH a weight
        #expect(ex.lastSets == 4)
    }

    @Test
    func summaryFormatsPerMetric() {
        let strength = Exercise(name: "Sentadilla", metric: .strength,
                                sessions: [WorkoutSession(weight: 120, date: Date())])
        #expect(strength.summary == MuscleCheck.SessionFormatting.formatWeight(kg: 120))

        let empty = Exercise(name: "Nueva", metric: .strength)
        #expect(empty.summary == nil)
    }

    @Test
    func muscleEntryStartsWithNoExercises() {
        let entry = MuscleEntry(name: "Piernas", category: "gym")
        #expect(entry.exercises.isEmpty)
    }
}
