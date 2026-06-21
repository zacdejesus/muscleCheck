//
//  ContentViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import Foundation
import SwiftData
import HealthKit

@MainActor
final class ContentViewModel: ObservableObject {
  
  private var context: ModelContextProtocol?
  private(set) var entries: [MuscleEntry] = []
  private var muscleEntryManager: MuscleEntryManager?
  @Published private(set) var currentWeekEntries: [MuscleEntry] = []
  @Published private(set) var groupedCurrentWeekEntries: [(category: String, entries: [MuscleEntry])] = []

  // MARK: - AI Coach (Feature 12)

  /// Current suggested day, shown (and filled progressively while streaming) in the
  /// coach modal. Version-agnostic so this iOS 18 view model can hold it.
  @Published var routineSuggestion: RoutineSuggestion?
  @Published var isGeneratingRoutine = false
  @Published var routineError: String?
  /// Groups from the last suggestion, excluded on "dame otra" to force a different day.
  private var lastSuggestedGroups: Set<String> = []

  /// Backing storage for the on-device AI. Held as `Any?` because `MuscleCheckAI`
  /// (FoundationModels) is only available on iOS 26+, while this view model targets iOS 18.
  private var aiStorage: Any?

  @available(iOS 26, *)
  private var muscleCheckAI: MuscleCheckAI {
    if let existing = aiStorage as? MuscleCheckAI { return existing }
    let new = MuscleCheckAI()
    aiStorage = new
    return new
  }

  /// Generates (or regenerates) a suggested training day from the eligible gym groups.
  /// Rotation/variety is resolved in code (`WorkoutEligibility`); the model only picks
  /// a coherent pair + example exercises. Free, on-device — no Pro gate.
  func generateRoutine(regenerate: Bool = false) async {
    guard #available(iOS 26, *) else { return }

    let previous = routineSuggestion
    isGeneratingRoutine = true
    routineError = nil

    let excluded = regenerate ? lastSuggestedGroups : []
    let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, excluding: excluded)

    // Nothing to suggest from (no gym groups at all).
    guard eligible.count >= 2 else {
      isGeneratingRoutine = false
      routineError = String(localized: "ERROR_GENERATING_ROUTINE")
      return
    }

    do {
      let suggestion = try await muscleCheckAI.suggestWorkout(eligible: eligible) { [weak self] partial in
        self?.routineSuggestion = partial
      }
      routineSuggestion = suggestion
      lastSuggestedGroups = Set(suggestion.blocks.map(\.groupName))
      cacheRoutine(suggestion)
    } catch {
      routineError = String(localized: "ERROR_GENERATING_ROUTINE")
      routineSuggestion = previous // restore prior suggestion (nil on first run)
    }

    isGeneratingRoutine = false
  }

  private func cacheRoutine(_ suggestion: RoutineSuggestion) {
    guard let data = try? JSONEncoder().encode(suggestion) else { return }
    UserDefaultsManager.shared.cachedRoutineData = data
    UserDefaultsManager.shared.cachedRoutineDate = Date()
  }

  private func loadCachedRoutineIfToday() {
    guard let date = UserDefaultsManager.shared.cachedRoutineDate,
          Date.appCalendar.isDate(date, inSameDayAs: Date()),
          let data = UserDefaultsManager.shared.cachedRoutineData,
          let cached = try? JSONDecoder().decode(RoutineSuggestion.self, from: data)
    else { return }
    routineSuggestion = cached
    lastSuggestedGroups = Set(cached.blocks.map(\.groupName))
  }

  func setup(context: ModelContextProtocol, entries: [MuscleEntry]) async {
    if #available(iOS 26, *) {
      muscleCheckAI.prewarmModel()
    }

    self.context = context
    self.entries = entries

    self.muscleEntryManager = .init(context: context)

    insertDefaultMuscleEntries()

    resetCheckedEntriesIfnewWeek()

    updateCurrentEntries()

    loadCachedRoutineIfToday()
  }
  
  func resetCheckedEntriesIfnewWeek() {
    let calendar = Date.appCalendar
    let currentWeek = calendar.component(.weekOfYear, from: Date())
    let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
    
    if currentWeek != UserDefaultsManager.shared.lastResetWeek ||
        currentYear != UserDefaultsManager.shared.lastResetYear {
      
      entries.forEach {
        $0.isChecked = false
        $0.weekOfYear = currentWeek
        $0.year = currentYear
      }
      do {
        try context?.save()
      } catch {
        assertionFailure("Failed to save context after resetting entries: \(error)")
      }
      
      UserDefaultsManager.shared.lastResetWeek = currentWeek
      UserDefaultsManager.shared.lastResetYear = currentYear
    }
  }
  
  func updateCurrentEntries() {
      do {
          guard let fetchEntries = try muscleEntryManager?.fetchAllEntries() else { return }
          entries = fetchEntries

          let calendar = Date.appCalendar
          let currentWeek = calendar.component(.weekOfYear, from: Date())
          let currentYear = calendar.component(.yearForWeekOfYear, from: Date())

          let filtered = entries.filter { $0.weekOfYear == currentWeek && $0.year == currentYear }
          if currentWeekEntries != filtered {
              currentWeekEntries = filtered
          }

          // Group entries by category in stable order
          let grouped = Dictionary(grouping: currentWeekEntries) { $0.category }
          groupedCurrentWeekEntries = grouped
              .sorted { lhs, rhs in
                  let lOrder = ActivityCategory(rawValue: lhs.key)?.sortOrder ?? 99
                  let rOrder = ActivityCategory(rawValue: rhs.key)?.sortOrder ?? 99
                  return lOrder < rOrder
              }
              .map { (category: $0.key, entries: $0.value) }

          let sharedEntries = currentWeekEntries.map { SharedMuscleEntry(name: $0.name, isChecked: $0.isChecked, icon: $0.icon) }
          let currentStreak = StreakCalculator.currentStreak(from: entries)
          let maxStreak = StreakCalculator.maxStreak(from: entries)
          Task.detached {
              do {
                  let data = try JSONEncoder().encode(sharedEntries)
                  let defaults = UserDefaults(suiteName: "group.zadkiel.musclecheck")
                  defaults?.set(data, forKey: "widgetEntries")
                  defaults?.set(currentStreak, forKey: "widgetCurrentStreak")
                  defaults?.set(maxStreak, forKey: "widgetMaxStreak")
              } catch {
                  assertionFailure("Failed to encode sharedEntries: \(error)")
              }
          }
      } catch {
          assertionFailure("Failed to fetch entries: \(error)")
      }
  }
  
  func toggleCheck(for entry: MuscleEntry) {
    entry.isChecked.toggle()
    updateCurrentEntries()
  }
  
  func insertDefaultMuscleEntries() {

    guard !UserDefaultsManager.shared.defaultEntriesCreated else { return }
    
    let defaultGroups = [
      NSLocalizedString("group_chest", comment: ""),
      NSLocalizedString("group_back", comment: ""),
      NSLocalizedString("group_legs", comment: ""),
      NSLocalizedString("group_shoulders", comment: ""),
      NSLocalizedString("group_biceps", comment: ""),
      NSLocalizedString("group_triceps", comment: ""),
      NSLocalizedString("group_abdomen", comment: "")
    ]
    
    for group in defaultGroups {
      let entry = MuscleEntry(name: group)
      entry.isChecked = false
      context?.insert(entry)
    }
    
    UserDefaultsManager.shared.defaultEntriesCreated = true
    do {
      try context?.save()
    } catch  {
      assertionFailure("Failed to save context after resetting entries: \(error)")
    }
  }
  
  /// Saves today's session (weight + optional sets/reps) for the muscle entry.
  /// Premise: "if I log something today, I trained today", so this also marks the entry as
  /// checked for the current week. Weight is expected to be in kg (the canonical storage unit).
  func saveSession(weight: Double?, sets: Int?, reps: Int?, for entry: MuscleEntry) {
    entry.setTodaySession(weight: weight, sets: sets, reps: reps)
    do {
      try context?.save()
    } catch {
      assertionFailure("Failed to save session: \(error)")
    }
    updateCurrentEntries()
  }

  func toggleActivity(for entry: MuscleEntry) {
    let today = Date()
    if entry.isChecked {
      entry.removeSession(matching: today)
    } else {
        entry.addSession(today)
    }
    entry.isChecked.toggle()
    do {
      try context?.save()
    } catch  {
      assertionFailure("Failed to save context after resetting entries: \(error)")
    }
    updateCurrentEntries()
  }
  
  func deleteEntries(at offsets: IndexSet) {
    for index in offsets {
      guard let entry = entries[safe: index] else { return  }
      context?.delete(entry)
    }
    try? context?.save()
  }
  
  func deleteEntries(from sectionEntries: [MuscleEntry], at offsets: IndexSet) {
    for index in offsets {
      guard let entry = sectionEntries[safe: index] else { return }
      context?.delete(entry)
    }
    try? context?.save()
    updateCurrentEntries()
  }
  
  func isAppleIntelligenceAvailable() -> Bool {
    guard #available(iOS 26, *) else { return false }
    return muscleCheckAI.isAppleIntelligenceAvailable()
  }

  /// Logs a HealthKit workout against the user-chosen entries. HealthKit only knows the
  /// activity type (e.g. "strength training"), not which muscles — so the caller picks the
  /// targets. If `targets` is empty (the category has no entries yet) a generic entry is
  /// created from the workout as a fallback.
  func logHealthKitWorkout(_ workout: HKWorkout, to targets: [MuscleEntry]) {
    guard let manager = muscleEntryManager else { return }

    let workoutDate = workout.startDate

    do {
      var entriesToLog = targets
      if entriesToLog.isEmpty {
        let category = HealthKitManager.mapToCategory(workout.workoutActivityType)
        let name = HealthKitManager.suggestedName(for: workout)
        let icon = HealthKitManager.iconForWorkout(workout)
        try manager.addEntry(name: name, category: category.rawValue, icon: icon)
        guard let created = try manager.fetchAllEntries()
          .first(where: { $0.name == name && $0.category == category.rawValue }) else { return }
        entriesToLog = [created]
      }

      for target in entriesToLog {
        target.addSession(workoutDate)
        if Date.appCalendar.isDate(workoutDate, equalTo: Date(), toGranularity: .weekOfYear) {
          target.isChecked = true
        }
        try manager.update(target)
      }
    } catch {
      return
    }

    updateCurrentEntries()
  }
}
