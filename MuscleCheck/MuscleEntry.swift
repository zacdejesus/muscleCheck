//
//  MuscleEntry.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import Foundation
import SwiftData

@Model
class MuscleEntry {
    var name: String
    var isChecked: Bool
    var weekOfYear: Int
    var year: Int
    var date: Date
    
    init(name: String, isChecked: Bool = false, date: Date = Date()) {
        self.name = name
        self.isChecked = isChecked
        self.date = date

        let calendar = Calendar.current
        self.weekOfYear = calendar.component(.weekOfYear, from: date)
        self.year = calendar.component(.yearForWeekOfYear, from: date)
    }
}
