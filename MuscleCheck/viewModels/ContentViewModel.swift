//
//  ContentViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import Foundation
import SwiftData

@MainActor
class ContentViewModel: ObservableObject {
  
  private var context: ModelContext?
  private var entries: [MuscleEntry] = []
  private var muscleEntryManager: MuscleEntryManager?
  
  @Published var currentWeekEntries: [MuscleEntry] = []
  
  func setup(context: ModelContext, entries: [MuscleEntry]) {
    self.context = context
    self.entries = entries
    
    self.muscleEntryManager = .init(context: context)
    
    createMissingEntriesIfNeeded()
    updateCurrentEntries()
  }
  
  func updateCurrentEntries() {
    
    guard let fetchEntries = try? (muscleEntryManager?.fetchAllEntries()) else { return }
    
    entries = fetchEntries
    
    let calendar = Calendar.current
    let currentWeek = calendar.component(.weekOfYear, from: Date())
    let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
    
    currentWeekEntries = entries.filter { $0.weekOfYear == currentWeek && $0.year == currentYear }
  }
  
  func toggleCheck(for entry: MuscleEntry) {
    entry.isChecked.toggle()
    updateCurrentEntries()
  }
  
  func insertDefaultMuscleEntries(context: ModelContext) {
    let now = Date()
    let week = Calendar.current.component(.weekOfYear, from: now)
    let year = Calendar.current.component(.yearForWeekOfYear, from: now)
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
      entry.date = now
      entry.weekOfYear = week
      entry.year = year
      entry.isChecked = false
      context.insert(entry)
    }
    
    try? context.save()
  }
  
  func createMissingEntriesIfNeeded() {
    let customGroups = entries.map { $0.name }
    
    let calendar = Calendar.current
    let currentWeek = calendar.component(.weekOfYear, from: Date())
    let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
    
    let allGroups = customGroups
    
    allGroups.forEach { name in
      let exists = entries.contains {
        $0.name == name && $0.weekOfYear == currentWeek && $0.year == currentYear
      }
      
      if !exists {
        try? muscleEntryManager?.addEntry(name: name)
      }
    }
    
    updateCurrentEntries()
  }
  
  func toggleActivity(for entry: MuscleEntry) {
    let today = Date()
      if entry.isChecked {
        entry.removeActivityDate(today)
      } else {
        entry.addActivityDate(today)
      }
    entry.isChecked.toggle()
    try? context?.save()
    updateCurrentEntries()
  }
  
  func deleteEntries(at offsets: IndexSet) {
    for index in offsets {
      let entry = entries[index]
      context?.delete(entry)
    }
    try? context?.save()
  }
  
  func emoji(for muscle: String) -> String {
    switch muscle {
    case NSLocalizedString("group_chest", comment: ""): return "🏋️"
    case NSLocalizedString("group_back", comment: ""): return "🦾"
    case NSLocalizedString("group_legs", comment: ""): return "🦵"
    case NSLocalizedString("group_shoulders", comment: ""): return "🧍‍♂️"
    case NSLocalizedString("group_biceps", comment: ""): return "💪"
    case NSLocalizedString("group_triceps", comment: ""): return "🔩"
    case NSLocalizedString("group_abdomen", comment: ""): return "🧘"
    default: return "🏋️"
    }
  }
}
