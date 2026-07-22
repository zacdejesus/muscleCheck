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
  /// Named exercises inside this group (Fase 2), e.g. "Peso muerto" under "Piernas".
  /// Additive Codable array with a `[]` default — the group's own `sessions` above
  /// still drive the weekly check/date semantics; these carry the detailed values.
  var exercises: [Exercise] = []
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
    /// Most recent session for which `value` is non-nil. Single O(n) scan — these
    /// getters run per row per render, so no sorting of the whole array.
    private func latestValue<T>(_ value: (WorkoutSession) -> T?) -> T? {
        var best: (date: Date, value: T)?
        for session in sessions {
            if let v = value(session), best.map({ session.date > $0.date }) ?? true {
                best = (session.date, v)
            }
        }
        return best?.value
    }

    var lastWeight: Double? { latestValue { $0.weight } }

    /// Most recent recorded sets ("series"), looking back across sessions. Nil if never recorded.
    var lastSets: Int? { latestValue { $0.sets } }

    /// Most recent recorded reps, looking back across sessions. Nil if never recorded.
    var lastReps: Int? { latestValue { $0.reps } }

    /// `lastWeight` (stored in kg) formatted in the user's preferred display unit,
    /// e.g. "20 kg" or "44 lbs". Nil if no session has a weight recorded yet.
    var formattedLastWeight: String? {
        lastWeight.map(SessionFormatting.formatWeight)
    }

    /// Most recent recorded duration (seconds), looking back across sessions.
    var lastDurationSeconds: Int? { latestValue { $0.durationSeconds } }

    /// Most recent recorded distance (meters), looking back across sessions.
    var lastDistanceMeters: Double? { latestValue { $0.distanceMeters } }

    /// Most recent session that recorded distance OR duration. Distance+duration
    /// consumers must read BOTH values from this one session — mixing per-field
    /// lookbacks would pair a Monday distance with a Wednesday time as if they
    /// happened together.
    var lastDistanceDurationSession: WorkoutSession? {
        sessions
            .filter { $0.distanceMeters != nil || $0.durationSeconds != nil }
            .max { $0.date < $1.date }
    }

    /// Row label for the entry's metric: "20 kg", "45 min", "5.2 km · 32 min".
    /// Nil when the metric logs nothing or nothing was recorded yet.
    var formattedLastMetric: String? {
        let cardio = metric == .distanceDuration ? lastDistanceDurationSession : nil
        return SessionFormatting.label(
            metric: metric,
            weightKg: lastWeight,
            durationSeconds: metric == .distanceDuration ? cardio?.durationSeconds : lastDurationSeconds,
            distanceMeters: cardio?.distanceMeters
        )
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

  /// Sets (or updates) today's weight for this muscle, preserving everything else already
  /// recorded for today (sets/reps/duration/distance — `setTodaySession` overwrites all
  /// fields, so anything not carried over here would be silently blanked).
  /// Premise: "if I set the weight, I trained today" — marks `isChecked = true`.
  func setTodaysWeight(_ weight: Double?) {
      let today = Date()
      let existing = sessions.first { Date.appCalendar.isDate($0.date, inSameDayAs: today) }
      setTodaySession(
          weight: weight,
          sets: existing?.sets,
          reps: existing?.reps,
          durationSeconds: existing?.durationSeconds,
          distanceMeters: existing?.distanceMeters
      )
  }

  // MARK: - Exercises (Fase 2)

  /// Appends a new exercise to this group and returns it.
  @discardableResult
  func addExercise(name: String, metric: MetricType, icon: String) -> Exercise {
      let ex = Exercise(name: name.trimmingCharacters(in: .whitespacesAndNewlines), icon: icon, metric: metric)
      exercises.append(ex)
      return ex
  }

  func deleteExercise(id: UUID) {
      exercises.removeAll { $0.id == id }
  }

  /// Logs today's values for one exercise AND marks the GROUP trained today, so the
  /// weekly check / streak / stats (which read the group's `sessions`) keep working
  /// untouched. Upserts today's session on the exercise (no duplicate per day).
  func logExercise(id: UUID, input: SessionInput, date: Date = Date()) {
      guard let idx = exercises.firstIndex(where: { $0.id == id }) else { return }
      let cal = Date.appCalendar
      if let sIdx = exercises[idx].sessions.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) }) {
          exercises[idx].sessions[sIdx].weight = input.weightKg
          exercises[idx].sessions[sIdx].sets = input.sets
          exercises[idx].sessions[sIdx].reps = input.reps
          exercises[idx].sessions[sIdx].durationSeconds = input.durationSeconds
          exercises[idx].sessions[sIdx].distanceMeters = input.distanceMeters
      } else {
          exercises[idx].sessions.append(WorkoutSession(
              weight: input.weightKg, sets: input.sets, reps: input.reps,
              durationSeconds: input.durationSeconds, distanceMeters: input.distanceMeters, date: date))
      }
      // Group is trained today (drives check / streak / stats / history dots).
      if !sessions.contains(where: { cal.isDate($0.date, inSameDayAs: date) }) {
          sessions.append(WorkoutSession(date: date))
      }
      isChecked = true
  }

  /// Row label under the group name. With exercises: "3 ejercicios · Peso muerto 100 kg"
  /// (count + the most recently logged exercise). Without exercises, falls back to the
  /// group's own single-value label so nothing regresses.
  var exercisesSummary: String? {
      guard !exercises.isEmpty else { return formattedLastMetric }
      let count = exercises.count
      let unit = NSLocalizedString(count == 1 ? "exercise_count_one" : "exercise_count_other", comment: "")
      let recent = exercises.max {
          ($0.sessions.map(\.date).max() ?? .distantPast) < ($1.sessions.map(\.date).max() ?? .distantPast)
      }
      if let recent, let value = recent.summary {
          return "\(count) \(unit) · \(recent.name) \(value)"
      }
      return "\(count) \(unit)"
  }
}
