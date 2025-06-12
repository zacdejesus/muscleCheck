//
//  HistoryViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 07/06/2025.
//


import Foundation
import SwiftData
import _SwiftData_SwiftUI

class HistoryViewModel: ObservableObject {
  
  @Published var selectedDate: Date = Date()
  @Published var entries: [MuscleEntry]

  init(entries: [MuscleEntry]) {
    self.entries = entries
  }

  static func create(with entries: [MuscleEntry]) -> HistoryViewModel {
    return HistoryViewModel(entries: entries)
  }
  
  var groupedEntries: [String: [MuscleEntry]] {
      let calendar = Date.appCalendar
      guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
          return [:]
      }

      let filtered = entries.filter { entry in
          entry.activityDates.contains { activityDate in
              weekInterval.contains(activityDate)
          }
      }

      return Dictionary(grouping: filtered, by: { $0.name })
  }
  
  func weekOf(_ date: Date) -> Int {
    Date.appCalendar.component(.weekOfYear, from: date)
  }
  
  func weekRangeString(for date: Date) -> String {
    let calendar = Date.appCalendar
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "" }
    
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "es_ES")
    formatter.dateFormat = "d 'de' MMMM"
    
    let start = formatter.string(from: weekInterval.start)
    let end = formatter.string(from: calendar.date(byAdding: .day, value: 6, to: weekInterval.start)!)
    
    return "del \(start) al \(end)"
  }
}
