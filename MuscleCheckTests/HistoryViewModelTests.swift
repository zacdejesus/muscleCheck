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

    private func makeEntry(name: String, dates: [Date]) -> MuscleEntry {
        let entry = MuscleEntry(name: name)
        for date in dates { entry.addSession(date) }
        return entry
    }

    @Test
    func testGroupedEntriesIncludesEntriesInSelectedWeek() {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        let entry1 = makeEntry(name: "Pecho", dates: [monday])
        let entry2 = makeEntry(name: "Espalda", dates: [tuesday])
        let entry3 = makeEntry(name: "Piernas", dates: [])

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

        let entry = makeEntry(name: "Pecho", dates: [nextWeek])
        let viewModel = HistoryViewModel(entries: [entry])
        viewModel.selectedDate = monday

        #expect(viewModel.groupedEntries.isEmpty)
    }

    @Test
    func testGroupedEntriesGroupsByMuscleName() {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!

        let entry1 = makeEntry(name: "Pecho", dates: [monday])
        let entry2 = makeEntry(name: "Pecho", dates: [monday])
        let entry3 = makeEntry(name: "Espalda", dates: [monday])

        let viewModel = HistoryViewModel(entries: [entry1, entry2, entry3])
        viewModel.selectedDate = monday

        let result = viewModel.groupedEntries

        #expect(result["Pecho"]?.count == 2)
        #expect(result["Espalda"]?.count == 1)
    }

    @Test
    func testGroupedEntriesHandlesMultipleSessions() {
        let calendar = Calendar(identifier: .gregorian)
        let monday = calendar.date(from: DateComponents(year: 2025, month: 6, day: 9))!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: monday)!

        let entry = makeEntry(name: "Pecho", dates: [monday, nextWeek])
        let viewModel = HistoryViewModel(entries: [entry])
        viewModel.selectedDate = monday

        // Entry is included once even though it has a session in another week
        #expect(viewModel.groupedEntries["Pecho"]?.count == 1)
    }
}
