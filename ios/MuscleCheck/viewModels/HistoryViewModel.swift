//
//  HistoryViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 07/06/2025.
//


import Foundation
import SwiftData

final class HistoryViewModel: ObservableObject {

    /// The day whose week is highlighted and whose breakdown is shown below the calendar.
    @Published var selectedDate: Date = Date()
    /// The month currently rendered in the grid (changed by the chevrons).
    @Published var displayedMonth: Date = Date()
    /// Calendar starts collapsed to the selected week; tapping the header expands it to the full month.
    @Published var isCalendarExpanded: Bool = false
    @Published var entries: [MuscleEntry]

    init(entries: [MuscleEntry]) {
        self.entries = entries
    }

    static func create(with entries: [MuscleEntry]) -> HistoryViewModel {
        return HistoryViewModel(entries: entries)
    }

    // MARK: - Calendar grid (delegates to MonthCalendarCalculator)

    var weeks: [[CalendarDay]] {
        MonthCalendarCalculator.monthMatrix(for: displayedMonth)
    }

    var intensityByDay: [Date: Int] {
        MonthCalendarCalculator.muscleCountByDay(from: entries)
    }

    var monthTrainedCount: Int {
        MonthCalendarCalculator.trainedDayCount(inMonthOf: displayedMonth, from: entries)
    }

    var weekBreakdown: [DayActivities] {
        MonthCalendarCalculator.weekBreakdown(forWeekContaining: selectedDate, from: entries)
    }

    /// The single Monday-first week shown when the calendar is collapsed.
    var selectedWeek: [CalendarDay] {
        MonthCalendarCalculator.weekRow(forWeekContaining: selectedDate)
    }

    /// "Junio 2026" — capitalized for the header.
    var monthTitle: String {
        Self.monthTitleFormatter.string(from: displayedMonth).capitalized
    }

    /// "junio" — lowercase, used mid-sentence in the month summary caption.
    var monthName: String {
        Self.monthNameFormatter.string(from: displayedMonth)
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        if let prev = Date.appCalendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = prev
        }
    }

    func goToNextMonth() {
        if let next = Date.appCalendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = next
        }
    }

    func select(_ day: Date) {
        selectedDate = day
        // Tapping a leading/trailing day follows it into its month (Calendar.app behavior).
        if !Date.appCalendar.isDate(day, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = day
        }
        // Picking a day collapses back to its week (Calendar.app behavior).
        isCalendarExpanded = false
    }

    func goToPreviousWeek() { shiftSelectedWeek(by: -1) }
    func goToNextWeek() { shiftSelectedWeek(by: 1) }

    /// Moves the collapsed view a week at a time, keeping `displayedMonth` (and the header
    /// label) in step with the visible week.
    private func shiftSelectedWeek(by value: Int) {
        guard let next = Date.appCalendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) else { return }
        selectedDate = next
        displayedMonth = next
    }

    func toggleCalendarExpanded() {
        isCalendarExpanded.toggle()
        // Expanding shows the month around the selected day.
        if isCalendarExpanded { displayedMonth = selectedDate }
    }

    // MARK: - Formatters

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return f
    }()

    private static let monthNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("LLLL")
        return f
    }()
}
