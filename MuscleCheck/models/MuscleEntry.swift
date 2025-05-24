//
//  MuscleEntry.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import Foundation
import SwiftData

@Model
class MuscleEntry: Identifiable, Hashable, Equatable {
    @Attribute(.unique) var id: UUID
    var name: String
    var isChecked: Bool
    var weekOfYear: Int
    var year: Int
    var isCustom: Bool
    var date: Date

    init(name: String, isCustom: Bool = false) {
        self.id = UUID()
        let now = Date()
        self.date = now
        self.name = name
        self.isChecked = false
        self.weekOfYear = Calendar.current.component(.weekOfYear, from: now)
        self.year = Calendar.current.component(.yearForWeekOfYear, from: now)
        self.isCustom = isCustom
    }
    
    static func == (lhs: MuscleEntry, rhs: MuscleEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
