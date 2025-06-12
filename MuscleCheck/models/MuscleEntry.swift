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
  var dateCreated: Date
  var activityDates: [Date]
  
  init(name: String, activityDates: [Date] = []) {
    self.id = UUID()
    
    let now = Date()
    let startOfWeek = now.startOfWeek() ?? now
    
    self.dateCreated = now
    self.name = name
    self.isChecked = false
    self.weekOfYear = Date.appCalendar.component(.weekOfYear, from: startOfWeek)
    self.year = Date.appCalendar.component(.yearForWeekOfYear, from: startOfWeek)
    self.activityDates = activityDates
  }
  
  static func == (lhs: MuscleEntry, rhs: MuscleEntry) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  func addActivityDate(_ date: Date) {
    if !activityDates.contains(where: { Date.appCalendar.isDate($0, inSameDayAs: date) }) {
      activityDates.append(date)
    }
  }
  
  func removeActivityDate(_ date: Date) {
    activityDates.removeAll(where: { Date.appCalendar.isDate($0, inSameDayAs: date) })
  }
}
