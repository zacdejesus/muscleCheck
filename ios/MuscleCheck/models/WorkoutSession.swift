//
//  WorkoutSession.swift
//  MuscleCheck
//
//  Created by z Air on 17/05/2026.
//

import SwiftData
import Foundation

/// Everything the session-log modal can capture in one save. Which fields are
/// non-nil depends on the entry's `MetricType`. Weight is in kg, distance in
/// meters, duration in seconds (canonical storage units).
struct SessionInput {
    var weightKg: Double? = nil
    var sets: Int? = nil
    var reps: Int? = nil
    var durationSeconds: Int? = nil
    var distanceMeters: Double? = nil
}

struct WorkoutSession: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var weight: Double?
    /// Number of sets ("series"). Optional — only strength sessions tend to fill it.
    var sets: Int?
    /// Repetitions per set. Optional.
    var reps: Int?
    /// Session length in seconds (duration / distanceDuration metrics). Optional —
    /// absent from legacy JSON, decodes as nil.
    var durationSeconds: Int?
    /// Distance in meters (distanceDuration metric). Optional.
    var distanceMeters: Double?

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        sets: Int? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        date: Date
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.sets = sets
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
    }

}
