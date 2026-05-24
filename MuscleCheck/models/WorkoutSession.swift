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

    init(id: UUID = UUID(), weight: Double? = nil, date: Date) {
        self.id = id
        self.date = date
        self.weight = weight
    }

}
