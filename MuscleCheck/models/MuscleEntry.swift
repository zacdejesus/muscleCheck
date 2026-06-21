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
  var category: String = ActivityCategory.gym.rawValue
  var icon: String = ActivityCategory.gym.defaultIcon
  var sessions: [WorkoutSession] = []
    var lastWeight: Double? {
        get {
            return sessions.sorted { $0.date > $1.date }.first(where: { $0.weight != nil })?.weight
        }
    }

    /// Most recent recorded sets ("series"), looking back across sessions. Nil if never recorded.
    var lastSets: Int? {
        sessions.sorted { $0.date > $1.date }.first(where: { $0.sets != nil })?.sets
    }

    /// Most recent recorded reps, looking back across sessions. Nil if never recorded.
    var lastReps: Int? {
        sessions.sorted { $0.date > $1.date }.first(where: { $0.reps != nil })?.reps
    }

    /// `lastWeight` (stored in kg) formatted in the user's preferred display unit,
    /// e.g. "20 kg" or "44 lbs". Nil if no session has a weight recorded yet.
    var formattedLastWeight: String? {
        guard let kg = lastWeight else { return nil }
        let unit = UserDefaultsManager.shared.weightUnit
        let display = unit.displayValue(fromKg: kg)
        // Weights are shown as whole numbers (no decimals) — round at the display boundary.
        return String(format: "%.0f", display) + " " + unit.displayLabel
    }
  
  init(name: String, category: String = ActivityCategory.gym.rawValue, icon: String = ActivityCategory.gym.defaultIcon) {
    self.id = UUID()
    
    let now = Date()
    let startOfWeek = now.startOfWeek() ?? now
    
    self.dateCreated = now
    self.name = name
    self.isChecked = false
    self.weekOfYear = Date.appCalendar.component(.weekOfYear, from: startOfWeek)
    self.year = Date.appCalendar.component(.yearForWeekOfYear, from: startOfWeek)
    self.category = category
    self.icon = icon
  }
  
  static func == (lhs: MuscleEntry, rhs: MuscleEntry) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

    func addSession(_ date: Date, weight: Double? = nil) {
        if !sessions.contains(where: { Date.appCalendar.isDate($0.date, inSameDayAs: date) }) {
            let weight = weight ?? self.lastWeight
                
            
                
          sessions.append(WorkoutSession(weight: weight, date: date))
      }
    }
    
  func removeSession(matching date: Date) {
      sessions.removeAll(where: { Date.appCalendar.isDate($0.date, inSameDayAs: date) })
  }

  /// Sets (or updates) today's session for this muscle: weight, sets ("series") and reps.
  /// Premise: "if I log something today, I trained today" — so this also marks `isChecked = true`.
  /// If a session already exists for today, it is updated in place (no duplicate session).
  func setTodaySession(weight: Double?, sets: Int? = nil, reps: Int? = nil) {
      let today = Date()
      if let idx = sessions.firstIndex(where: { Date.appCalendar.isDate($0.date, inSameDayAs: today) }) {
          sessions[idx].weight = weight
          sessions[idx].sets = sets
          sessions[idx].reps = reps
      } else {
          sessions.append(WorkoutSession(weight: weight, sets: sets, reps: reps, date: today))
      }
      isChecked = true
  }

  /// Sets (or updates) today's weight for this muscle, preserving any sets/reps already
  /// recorded for today. Premise: "if I set the weight, I trained today" — marks `isChecked = true`.
  func setTodaysWeight(_ weight: Double?) {
      let today = Date()
      let existing = sessions.first { Date.appCalendar.isDate($0.date, inSameDayAs: today) }
      setTodaySession(weight: weight, sets: existing?.sets, reps: existing?.reps)
  }
}
