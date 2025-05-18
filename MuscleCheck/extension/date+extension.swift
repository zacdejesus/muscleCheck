//
//  date+extension.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import Foundation


extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }

    func endOfWeek(using calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 7, to: startOfWeek(using: calendar))!
    }
}
