//
//  WorkoutSession.swift
//  MuscleCheck
//
//  Created by z Air on 17/05/2026.
//

import SwiftData
import Foundation

struct WorkoutSession: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var weight: Double?
    /// Number of sets ("series"). Optional — only gym sessions tend to fill it.
    var sets: Int?
    /// Repetitions per set. Optional.
    var reps: Int?

    init(id: UUID = UUID(), weight: Double? = nil, sets: Int? = nil, reps: Int? = nil, date: Date) {
        self.id = id
        self.date = date
        self.weight = weight
        self.sets = sets
        self.reps = reps
    }

}
