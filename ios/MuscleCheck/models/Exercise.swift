//
//  Exercise.swift
//  MuscleCheck — Feature: exercises inside a group (Fase 2)
//
//  A named exercise inside a group (e.g. "Peso muerto" under "Piernas"). Stored
//  inline as a Codable array on `MuscleEntry.exercises` — the SAME pattern as
//  `WorkoutSession`, so adding it is an ADDITIVE, lightweight-migration-safe schema
//  change: SwiftData persists it as a transformable blob column with a default `[]`,
//  exactly like `sessions`. No new @Model, no AppSchema change, no two-container
//  invariant to worry about.
//
//  The group keeps its own `sessions` for the WEEKLY CHECK / date semantics (streak,
//  stats, notifications, HealthKit all read those) — exercises are a DETAIL layer
//  that carries the per-exercise values. Logging an exercise also marks the group
//  trained that day, so the date consumers keep working untouched.
//

import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    /// Raw `MetricType`. Each exercise logs its OWN thing (deadlift = strength,
    /// plank = duration), independent of the group's default.
    var metricRaw: String
    /// This exercise's own value history.
    var sessions: [WorkoutSession]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "figure.strengthtraining.traditional",
        metric: MetricType = .strength,
        sessions: [WorkoutSession] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.metricRaw = metric.rawValue
        self.sessions = sessions
    }

    var metric: MetricType {
        get { MetricType(rawValue: metricRaw) ?? .strength }
        set { metricRaw = newValue.rawValue }
    }

    /// Most recent session for which `value` is non-nil — single O(n) scan, mirroring
    /// `MuscleEntry.latestValue`.
    private func latestValue<T>(_ value: (WorkoutSession) -> T?) -> T? {
        var best: (date: Date, value: T)?
        for session in sessions {
            if let v = value(session), best.map({ session.date > $0.date }) ?? true {
                best = (session.date, v)
            }
        }
        return best?.value
    }

    var lastWeight: Double? { latestValue { $0.weight } }
    var lastSets: Int? { latestValue { $0.sets } }
    var lastReps: Int? { latestValue { $0.reps } }
    var lastDurationSeconds: Int? { latestValue { $0.durationSeconds } }
    var lastDistanceMeters: Double? { latestValue { $0.distanceMeters } }

    /// Most recent session recording distance OR duration — read BOTH values from
    /// this one session so a distance from one day and a time from another aren't
    /// paired as if done together.
    var lastDistanceDurationSession: WorkoutSession? {
        sessions
            .filter { $0.distanceMeters != nil || $0.durationSeconds != nil }
            .max { $0.date < $1.date }
    }

    /// Row label for this exercise under the group ("100 kg · 3×8", "45 min", …).
    var summary: String? {
        SessionFormatting.label(
            metric: metric,
            weightKg: lastWeight,
            durationSeconds: lastDurationSeconds,
            distanceMeters: lastDistanceMeters
        )
    }
}
