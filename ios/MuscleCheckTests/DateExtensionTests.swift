//
//  DateExtensionTests.swift
//  MuscleCheck
//
//  Covers the week-boundary helpers that every weekly calculation depends on.
//  Key invariant: the app week starts on Monday (firstWeekday = 2).
//

import Testing
@testable import MuscleCheck
import Foundation

struct DateExtensionTests {

    /// Builds a date at noon (avoids midnight/DST edge cases) using the app calendar.
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = 12
        return Date.appCalendar.date(from: c)!
    }

    @Test
    func testAppCalendarIsGregorianStartingMonday() {
        #expect(Date.appCalendar.identifier == .gregorian)
        #expect(Date.appCalendar.firstWeekday == 2)
    }

    @Test
    func testStartOfWeekReturnsMondayOfThatWeek() {
        // 2025-01-15 is a Wednesday; its week's Monday is 2025-01-13.
        let wednesday = date(2025, 1, 15)
        let start = wednesday.startOfWeek()
        #expect(start != nil)
        let cal = Date.appCalendar
        #expect(cal.component(.year, from: start!) == 2025)
        #expect(cal.component(.month, from: start!) == 1)
        #expect(cal.component(.day, from: start!) == 13)
        // Gregorian weekday: Sunday = 1, Monday = 2.
        #expect(cal.component(.weekday, from: start!) == 2)
    }

    @Test
    func testStartOfWeekOnMondayReturnsSameDay() {
        let monday = date(2025, 1, 13)
        let start = monday.startOfWeek()
        #expect(start.map { Date.appCalendar.isDate($0, inSameDayAs: monday) } == true)
    }

    @Test
    func testStartOfWeekIsIdempotent() {
        let d = date(2025, 1, 15)
        let once = d.startOfWeek()!
        let twice = once.startOfWeek()!
        #expect(Date.appCalendar.isDate(once, inSameDayAs: twice))
    }

    @Test
    func testEndOfWeekIsSundaySixDaysAfterStart() {
        let wednesday = date(2025, 1, 15)
        let start = wednesday.startOfWeek()!
        let end = wednesday.endOfWeek()!
        let cal = Date.appCalendar
        // End is the Sunday closing the week: 2025-01-19.
        #expect(cal.component(.day, from: end) == 19)
        #expect(cal.component(.weekday, from: end) == 1) // Sunday
        let days = cal.dateComponents([.day], from: start, to: end).day
        #expect(days == 6)
    }
}
