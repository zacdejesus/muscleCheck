//
//  HistoryViewModelTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 07/06/2025.
//

import Testing
@testable import MuscleCheck
import Foundation

struct HistoryViewModelTests {
  
  
  @Test
  func testGroupedEntriesIncludesEntriesInSelectedWeek() {
    let calendar = Calendar(identifier: .gregorian)
    let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!
    let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
    
    let entry1 = MuscleEntry(name: "Pecho", activityDates: [monday])
    let entry2 = MuscleEntry(name: "Espalda", activityDates: [tuesday])
    let entry3 = MuscleEntry(name: "Piernas", activityDates: [])
    
    let viewModel = HistoryViewModel(entries: [entry1, entry2, entry3])
    viewModel.selectedDate = monday
    
    let result = viewModel.groupedEntries
    
    #expect(result["Pecho"]?.count == 1)
    #expect(result["Espalda"]?.count == 1)
    #expect(result["Piernas"] == nil)
  }
  
  @Test
  func testGroupedEntriesExcludesEntriesOutsideSelectedWeek() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 8))!
    let nextWeek = calendar.date(byAdding: .day, value: 7, to: monday)!
    
    let entry = MuscleEntry(name: "Pecho", activityDates: [nextWeek])
    let viewModel = HistoryViewModel(entries: [entry])
    viewModel.selectedDate = monday
    
    
    let weekInterval = calendar.dateInterval(of: .weekOfYear, for: monday)!
    print("Semana seleccionada: \(weekInterval)")
    print("Fecha de actividad: \(nextWeek)")
    
    
    let result = viewModel.groupedEntries
    
    #expect(result.isEmpty)
  }
  
  @Test
  func testGroupedEntriesGroupsByMuscleName() {
    let calendar = Calendar(identifier: .gregorian)
    let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!
    
    let entry1 = MuscleEntry(name: "Pecho", activityDates: [monday])
    let entry2 = MuscleEntry(name: "Pecho", activityDates: [monday])
    let entry3 = MuscleEntry(name: "Espalda", activityDates: [monday])
    
    let viewModel = HistoryViewModel(entries: [entry1, entry2, entry3])
    viewModel.selectedDate = monday
    
    let result = viewModel.groupedEntries
    
    #expect(result["Pecho"]?.count == 2)
    #expect(result["Espalda"]?.count == 1)
  }
  
  @Test
  func testGroupedEntriesHandlesMultipleActivityDates() {
    let calendar = Calendar(identifier: .gregorian)
    let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!
    let nextWeek = calendar.date(byAdding: .day, value: 7, to: monday)!
    
    let entry = MuscleEntry(name: "Pecho", activityDates: [monday, nextWeek])
    let viewModel = HistoryViewModel(entries: [entry])
    viewModel.selectedDate = monday
    
    let result = viewModel.groupedEntries
    
    #expect(result["Pecho"]?.count == 1)
  }
}
