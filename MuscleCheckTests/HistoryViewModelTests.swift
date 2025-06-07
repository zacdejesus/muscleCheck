//
//  HistoryViewModelTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 07/06/2025.
//


import Testing
import Foundation
@testable import MuscleCheck

struct HistoryViewModelTests {
    
    @Test
    func testGroupedEntriesFiltersCorrectly() {
        let date = Date()
        let entries = [
            MuscleEntry(name: "Chest"),
            MuscleEntry(name: "Chest"),
            MuscleEntry(name: "Back")
        ]
        
        let viewModel = HistoryViewModel(entries: entries)
        viewModel.selectedDate = date
        
        let grouped = viewModel.groupedEntries
        
        #expect(grouped["Chest"]?.count == 2)
        #expect(grouped["Back"]?.count == 1)
    }

    @Test
    func testWeekRangeStringFormat() {
        let viewModel = HistoryViewModel(entries: [])
        let result = viewModel.weekRangeString(for: Date())
        
        #expect(result.contains("de"))
    }
}
