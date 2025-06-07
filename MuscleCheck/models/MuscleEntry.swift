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
  var date: Date
  var activityDates: [Date]
  
  init(name: String) {
    self.id = UUID()
    let now = Date()
    self.date = now
    self.name = name
    self.isChecked = false
    self.weekOfYear = Calendar.current.component(.weekOfYear, from: now)
    self.year = Calendar.current.component(.yearForWeekOfYear, from: now)
    self.activityDates = []
  }
  
  static func == (lhs: MuscleEntry, rhs: MuscleEntry) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  func addActivityDate(_ date: Date) {
    if !activityDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
      activityDates.append(date)
    }
  }
  
  func removeActivityDate(_ date: Date) {
    activityDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: date) })
  }
}
