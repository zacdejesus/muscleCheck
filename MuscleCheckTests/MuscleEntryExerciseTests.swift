//
//  MuscleEntryExerciseTests.swift
//  MuscleCheckTests — Feature: exercises inside a group (Fase 2)
//
//  The group owns exercises; logging one must also mark the GROUP trained (so the
//  check/streak/stats keep reading the group's sessions), and the row summary must
//  reflect the exercises.
//

import Testing
@testable import MuscleCheck
import Foundation

struct MuscleEntryExerciseTests {

    @Test
    func addAndDeleteExercise() {
        let group = MuscleEntry(name: "Piernas", category: "gym")
        let ex = group.addExercise(name: "Peso muerto", metric: .strength, icon: "x")
        #expect(group.exercises.count == 1)
        #expect(group.exercises.first?.name == "Peso muerto")

        group.deleteExercise(id: ex.id)
        #expect(group.exercises.isEmpty)
    }

    @Test
    func loggingAnExerciseMarksTheGroupTrained() {
        let group = MuscleEntry(name: "Piernas", category: "gym")
        let ex = group.addExercise(name: "Peso muerto", metric: .strength, icon: "x")

        group.logExercise(id: ex.id, input: SessionInput(weightKg: 100, sets: 3, reps: 8))

        // Exercise carries the value...
        #expect(group.exercises.first?.lastWeight == 100)
        #expect(group.exercises.first?.sessions.count == 1)
        // ...and the group is trained today (drives check / streak / stats).
        #expect(group.isChecked)
        #expect(group.sessions.contains { Date.appCalendar.isDateInToday($0.date) })
    }

    @Test
    func loggingTwiceSameDayUpdatesInPlace() {
        let group = MuscleEntry(name: "Piernas", category: "gym")
        let ex = group.addExercise(name: "Peso muerto", metric: .strength, icon: "x")

        group.logExercise(id: ex.id, input: SessionInput(weightKg: 100))
        group.logExercise(id: ex.id, input: SessionInput(weightKg: 110))

        #expect(group.exercises.first?.sessions.count == 1)   // no duplicate for today
        #expect(group.exercises.first?.lastWeight == 110)
    }

    @Test
    func summaryCountsExercisesAndShowsMostRecent() {
        let group = MuscleEntry(name: "Piernas", category: "gym")
        let cal = Date.appCalendar
        let deadlift = group.addExercise(name: "Peso muerto", metric: .strength, icon: "x")
        let hip = group.addExercise(name: "Hip thrust", metric: .strength, icon: "x")

        // Deadlift logged earlier, hip thrust just now → hip thrust is "most recent".
        group.logExercise(id: deadlift.id, input: SessionInput(weightKg: 100),
                          date: cal.date(byAdding: .day, value: -1, to: Date())!)
        group.logExercise(id: hip.id, input: SessionInput(weightKg: 80))

        let summary = group.exercisesSummary ?? ""
        #expect(summary.contains("2"))            // count
        #expect(summary.contains("Hip thrust"))   // most recently logged
        #expect(summary.contains("80"))
    }

    @Test
    func emptyGroupSummaryFallsBackToGroupValue() {
        let group = MuscleEntry(name: "Piernas", category: "gym")
        #expect(group.exercises.isEmpty)
        // No exercises, no group session → nothing to summarize.
        #expect(group.exercisesSummary == nil)
    }
}
