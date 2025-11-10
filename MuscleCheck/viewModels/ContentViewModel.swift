//
//  ContentViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import Foundation
import SwiftData
import FoundationModels

@MainActor
final class ContentViewModel: ObservableObject {
  
  private var context: ModelContextProtocol?
  private(set) var entries: [MuscleEntry] = []
  private var muscleEntryManager: MuscleEntryManager?
  @Published private(set) var currentWeekEntries: [MuscleEntry] = []
  @Published var workoutSuggested: String.PartiallyGenerated?
  
  let muscleCheckAI = MuscleCheckAI()
  let session = LanguageModelSession()
  
  func reviewLastMonthWorkouts() async {
    do {
      workoutSuggested = try await muscleCheckAI.generateReview(entries: entries)
    } catch {
      workoutSuggested = String(localized: "ERROR_GENERATING_REVIEW")
    }
  }
  
  func setup(context: ModelContextProtocol, entries: [MuscleEntry]) async {
    muscleCheckAI.prewarmModel()
    
    self.context = context
    self.entries = entries
    
    self.muscleEntryManager = .init(context: context)
    
    insertDefaultMuscleEntries()

    resetCheckedEntriesIfnewWeek()
    
    updateCurrentEntries()
  }
  
  func resetCheckedEntriesIfnewWeek() {
    let calendar = Date.appCalendar
    let currentWeek = calendar.component(.weekOfYear, from: Date())
    let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
    
    if currentWeek != UserDefaultsManager.shared.lastResetWeek ||
        currentYear != UserDefaultsManager.shared.lastResetYear {
      
      entries.forEach { $0.isChecked = false }
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

          let sharedEntries = currentWeekEntries.map { SharedMuscleEntry(name: $0.name, isChecked: $0.isChecked) }
          Task.detached {
              do {
                  let data = try JSONEncoder().encode(sharedEntries)
                  let defaults = UserDefaults(suiteName: "group.zadkiel.musclecheck")
                  defaults?.set(data, forKey: "widgetEntries")
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
  
  func toggleActivity(for entry: MuscleEntry) {
    let today = Date()
    if entry.isChecked {
      entry.removeActivityDate(today)
    } else {
      entry.addActivityDate(today)
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
  
  func isAppleIntelligenceAvailable() -> Bool {
    return muscleCheckAI.isAppleIntelligenceAvailable()
  }
}
