//
//  date+extension.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import Foundation


extension Date {
  
  static var appCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    return calendar
  }
  
  func startOfWeek(using calendar: Calendar = Date.appCalendar) -> Date? {
    calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
  }
  
  func endOfWeek(using calendar: Calendar = Date.appCalendar) -> Date? {
    guard let start = startOfWeek(using: calendar) else { return nil }
    return calendar.date(byAdding: .day, value: 6, to: start)
  }
}
