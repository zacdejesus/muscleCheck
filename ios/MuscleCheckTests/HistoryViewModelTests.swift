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

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Date.appCalendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    // MARK: - Selection

    @Test
    func testSelectSetsSelectedDate() {
        let vm = HistoryViewModel(entries: [])
        let day = date(2026, 6, 10)
        vm.select(day)
        #expect(vm.selectedDate == day)
    }

    @Test
    func testSelectingDayInAnotherMonthPagesToIt() {
        let vm = HistoryViewModel(entries: [])
        vm.displayedMonth = date(2026, 6, 15)
        let julyDay = date(2026, 7, 2)
        vm.select(julyDay)
        #expect(Date.appCalendar.isDate(vm.displayedMonth, equalTo: julyDay, toGranularity: .month))
    }

    @Test
    func testSelectingDayCollapsesCalendar() {
        let vm = HistoryViewModel(entries: [])
        vm.isCalendarExpanded = true
        vm.select(date(2026, 6, 10))
        #expect(vm.isCalendarExpanded == false)
    }

    // MARK: - Expand / collapse

    @Test
    func testToggleExpandFlipsAndShowsSelectedMonth() {
        let vm = HistoryViewModel(entries: [])
        vm.selectedDate = date(2026, 6, 10)
        vm.displayedMonth = date(2026, 9, 1) // drifted via month paging
        vm.toggleCalendarExpanded()
        #expect(vm.isCalendarExpanded == true)
        #expect(Date.appCalendar.isDate(vm.displayedMonth, equalTo: vm.selectedDate, toGranularity: .month))
    }

    // MARK: - Week paging (collapsed)

    @Test
    func testWeekPagingMovesSelectionBySevenDays() {
        let vm = HistoryViewModel(entries: [])
        let start = date(2026, 6, 10)
        vm.selectedDate = start
        vm.goToNextWeek()
        #expect(Date.appCalendar.component(.day, from: vm.selectedDate) == 17)
        vm.goToPreviousWeek()
        vm.goToPreviousWeek()
        #expect(Date.appCalendar.component(.day, from: vm.selectedDate) == 3)
    }

    @Test
    func testWeekPagingKeepsMonthLabelInSync() {
        let vm = HistoryViewModel(entries: [])
        vm.selectedDate = date(2026, 6, 29) // last week of June
        vm.goToNextWeek()                    // into July
        #expect(Date.appCalendar.component(.month, from: vm.displayedMonth) == 7)
    }

    // MARK: - Month paging

    @Test
    func testGoToNextAndPreviousMonthShiftByOneMonth() {
        let vm = HistoryViewModel(entries: [])
        vm.displayedMonth = date(2026, 6, 15)
        vm.goToNextMonth()
        #expect(Date.appCalendar.component(.month, from: vm.displayedMonth) == 7)
        vm.goToPreviousMonth()
        vm.goToPreviousMonth()
        #expect(Date.appCalendar.component(.month, from: vm.displayedMonth) == 5)
    }

    @Test
    func testPagingDoesNotMoveSelection() {
        let vm = HistoryViewModel(entries: [])
        let selected = date(2026, 6, 10)
        vm.selectedDate = selected
        vm.displayedMonth = date(2026, 6, 1)
        vm.goToNextMonth()
        #expect(vm.selectedDate == selected) // chevrons don't move the highlighted week
    }

    // MARK: - Derived data

    @Test
    func testWeekBreakdownReflectsSelectedDate() {
        let entry = makeEntry(name: "Pecho", dates: [date(2026, 6, 8)])
        let vm = HistoryViewModel(entries: [entry])
        vm.select(date(2026, 6, 10)) // same week as June 8
        #expect(vm.weekBreakdown.count == 1)
        #expect(vm.weekBreakdown.first?.activities.first?.entry.name == "Pecho")
    }

    @Test
    func testMonthTrainedCountReflectsDisplayedMonth() {
        let entry = makeEntry(name: "Pecho", dates: [date(2026, 6, 1), date(2026, 6, 15), date(2026, 5, 20)])
        let vm = HistoryViewModel(entries: [entry])
        vm.displayedMonth = date(2026, 6, 10)
        #expect(vm.monthTrainedCount == 2) // only June days
        vm.displayedMonth = date(2026, 5, 10)
        #expect(vm.monthTrainedCount == 1)
    }
}
