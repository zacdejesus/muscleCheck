//
//  ContentViewModelTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 10/06/2025.
//


import Testing
@testable import MuscleCheck
import SwiftData
import Foundation

struct ContentViewModelTests {
  
  @MainActor @Test
  func testInsertDefaultMuscleEntriesOnlyOnce() {
    let context = MockContext()
    UserDefaultsManager.shared.defaultEntriesCreated = false
    
    let viewModel = ContentViewModel()
    viewModel.setup(context: context, entries: [])
    
    #expect(context.inserted.count > 0)
    #expect(UserDefaultsManager.shared.defaultEntriesCreated == true)
  }
  
  @MainActor @Test
  func testResetCheckedEntriesIfNewWeek() {
    let calendar = Date.appCalendar
    let now = Date()
    let currentWeek = calendar.component(.weekOfYear, from: now)
    let currentYear = calendar.component(.yearForWeekOfYear, from: now)
    
    UserDefaultsManager.shared.lastResetWeek = currentWeek - 1
    UserDefaultsManager.shared.lastResetYear = currentYear
    
    let entry = MuscleEntry(name: "Pecho")
    entry.isChecked = true
    
    let context = MockContext()
    let viewModel = ContentViewModel()
    viewModel.setup(context: context, entries: [entry])
    
    #expect(entry.isChecked == false)
    #expect(UserDefaultsManager.shared.lastResetWeek == currentWeek)
  }
  
  @MainActor @Test
  func testToggleCheckChangesState() {
    let entry = MuscleEntry(name: "Espalda")
    entry.isChecked = false
    
    let viewModel = ContentViewModel()
    viewModel.setup(context: MockContext(), entries: [entry])
    viewModel.toggleCheck(for: entry)
    
    #expect(entry.isChecked == true)
  }
  
  @MainActor @Test
  func testToggleActivityAddsAndRemovesDate() {
    let entry = MuscleEntry(name: "Piernas")
    let viewModel = ContentViewModel()
    viewModel.setup(context: MockContext(), entries: [entry])
    
    viewModel.toggleActivity(for: entry)
    #expect(entry.isChecked == true)
    #expect(entry.activityDates.contains(where: { Calendar.current.isDateInToday($0) }))
    
    viewModel.toggleActivity(for: entry)
    #expect(entry.isChecked == false)
    #expect(entry.activityDates.isEmpty)
  }
  
  @MainActor @Test
  func testEmojiReturnsCorrectSymbol() {
    let viewModel = ContentViewModel()
    let emoji = viewModel.emoji(for: NSLocalizedString("group_chest", comment: ""))
    #expect(emoji == "🏋️")
  }
}
