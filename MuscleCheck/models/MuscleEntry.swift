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
  /// Raw `MetricType`. Empty string = pre-metric entry — resolved lazily from the
  /// category (so legacy gym entries become `.strength` without a store write).
  /// Deliberately NOT defaulted to "none": that would mis-migrate old gym entries.
  var metricRaw: String = ""

  /// What this exercise logs when checked. Per-entry; the category only supplies
  /// the default. `backfillMetricTypes()` persists the lazy value once at startup.
  var metric: MetricType {
    get { MetricType(rawValue: metricRaw) ?? ActivityCategory(rawValue: category)?.defaultMetric ?? .none }
    set { metricRaw = newValue.rawValue }
  }
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

    /// Most recent recorded duration (seconds), looking back across sessions.
    var lastDurationSeconds: Int? {
        sessions.sorted { $0.date > $1.date }.first(where: { $0.durationSeconds != nil })?.durationSeconds
    }

    /// Most recent recorded distance (meters), looking back across sessions.
    var lastDistanceMeters: Double? {
        sessions.sorted { $0.date > $1.date }.first(where: { $0.distanceMeters != nil })?.distanceMeters
    }

    /// Row label for the entry's metric: "20 kg", "45 min", "5.2 km · 32 min".
    /// Nil when the metric logs nothing or nothing was recorded yet.
    var formattedLastMetric: String? {
        switch metric {
        case .none:
            return nil
        case .strength:
            return formattedLastWeight
        case .duration:
            return lastDurationSeconds.map(SessionFormatting.formatDuration)
        case .distanceDuration:
            let parts = [
                lastDistanceMeters.map(SessionFormatting.formatDistance),
                lastDurationSeconds.map(SessionFormatting.formatDuration)
            ].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }
    }

  /// `metric` nil = follow the category default (a default parameter can't reference
  /// `category`; custom-category defaults are resolved by the caller/manager).
  init(name: String, category: String = ActivityCategory.gym.rawValue, icon: String = ActivityCategory.gym.defaultIcon, metric: MetricType? = nil) {
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
    self.metricRaw = (metric ?? ActivityCategory(rawValue: category)?.defaultMetric ?? .none).rawValue
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
  func setTodaySession(weight: Double?, sets: Int? = nil, reps: Int? = nil, durationSeconds: Int? = nil, distanceMeters: Double? = nil) {
      let today = Date()
      if let idx = sessions.firstIndex(where: { Date.appCalendar.isDate($0.date, inSameDayAs: today) }) {
          sessions[idx].weight = weight
          sessions[idx].sets = sets
          sessions[idx].reps = reps
          sessions[idx].durationSeconds = durationSeconds
          sessions[idx].distanceMeters = distanceMeters
      } else {
          sessions.append(WorkoutSession(weight: weight, sets: sets, reps: reps, durationSeconds: durationSeconds, distanceMeters: distanceMeters, date: today))
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
