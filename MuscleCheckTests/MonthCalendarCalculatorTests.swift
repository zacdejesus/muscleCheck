//
//  MonthCalendarCalculatorTests.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 13/06/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

struct MonthCalendarCalculatorTests {

    // MARK: - Helpers

    /// Noon-anchored date (dodges midnight/DST edges), built with the app calendar.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour
        return Date.appCalendar.date(from: c)!
    }

    private func makeEntry(name: String, dates: [Date]) -> MuscleEntry {
        let entry = MuscleEntry(name: name)
        for d in dates { entry.addSession(d) }
        return entry
    }

    // MARK: - monthMatrix
    // (June 1 2026 is a Monday; Feb 1 2026 is a Sunday — used as fixtures below.)

    @Test
    func testMonthMatrixAlways42CellsSixRows() {
        let m = MonthCalendarCalculator.monthMatrix(for: date(2026, 6, 15))
        #expect(m.count == 6)
        #expect(m.allSatisfy { $0.count == 7 })
        #expect(m.flatMap { $0 }.count == 42)
    }

    @Test
    func testMonthMatrixFirstCellIsMondayOnOrBeforeFirstOfMonth() {
        let m = MonthCalendarCalculator.monthMatrix(for: date(2026, 6, 15))
        let cal = Date.appCalendar
        let firstCell = m[0][0].date
        #expect(cal.component(.weekday, from: firstCell) == 2) // Monday
        #expect(firstCell <= cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!)
    }

    @Test
    func testMonthMatrixMondayStartMonthHasNoLeadingDimmedDays() {
        // June 1 2026 is a Monday → grid starts exactly on the 1st.
        let m = MonthCalendarCalculator.monthMatrix(for: date(2026, 6, 10))
        #expect(Date.appCalendar.component(.day, from: m[0][0].date) == 1)
        #expect(m[0][0].isInDisplayedMonth == true)
    }

    @Test
    func testMonthMatrixSundayStartMonthHasSixLeadingDimmedDays() {
        // Feb 1 2026 is a Sunday → 6 leading days from January.
        let m = MonthCalendarCalculator.monthMatrix(for: date(2026, 2, 10))
        let cal = Date.appCalendar
        #expect(m[0][0].isInDisplayedMonth == false)              // Jan 26 (Mon)
        #expect(cal.component(.weekday, from: m[0][0].date) == 2)
        #expect(cal.component(.day, from: m[0][6].date) == 1)     // Feb 1 lands on Sunday column
        #expect(m[0][6].isInDisplayedMonth == true)
    }

    @Test
    func testMonthMatrixTrailingCellsBelongToNextMonth() {
        let m = MonthCalendarCalculator.monthMatrix(for: date(2026, 6, 10))
        #expect(m[5][6].isInDisplayedMonth == false) // last cell spills into July
    }

    // MARK: - trainedDays

    @Test
    func testTrainedDaysEmpty() {
        #expect(MonthCalendarCalculator.trainedDays(from: []).isEmpty)
    }

    @Test
    func testTrainedDaysDedupesSameDayAcrossEntries() {
        let e1 = makeEntry(name: "Pecho", dates: [date(2026, 6, 10, hour: 9)])
        let e2 = makeEntry(name: "Espalda", dates: [date(2026, 6, 10, hour: 18)])
        #expect(MonthCalendarCalculator.trainedDays(from: [e1, e2]).count == 1)
    }

    @Test
    func testTrainedDaysAdjacentDaysAreDistinct() {
        let e = makeEntry(name: "Pecho", dates: [date(2026, 6, 10, hour: 23), date(2026, 6, 11, hour: 1)])
        #expect(MonthCalendarCalculator.trainedDays(from: [e]).count == 2)
    }

    // MARK: - muscleCountByDay

    @Test
    func testMuscleCountByDayCountsDistinctMuscles() {
        let e1 = makeEntry(name: "Pecho", dates: [date(2026, 6, 10)])
        let e2 = makeEntry(name: "Espalda", dates: [date(2026, 6, 10)])
        let day = Date.appCalendar.startOfDay(for: date(2026, 6, 10))
        #expect(MonthCalendarCalculator.muscleCountByDay(from: [e1, e2])[day] == 2)
    }

    @Test
    func testMuscleCountByDaySameMuscleTwiceSameDayCountsOne() {
        let e = makeEntry(name: "Pecho", dates: [date(2026, 6, 10, hour: 9), date(2026, 6, 10, hour: 18)])
        let day = Date.appCalendar.startOfDay(for: date(2026, 6, 10))
        #expect(MonthCalendarCalculator.muscleCountByDay(from: [e])[day] == 1)
    }

    // MARK: - trainedDayCount

    @Test
    func testTrainedDayCountOnlyCountsAnchorMonth() {
        let e = makeEntry(name: "Pecho", dates: [date(2026, 5, 30), date(2026, 6, 1), date(2026, 6, 15)])
        #expect(MonthCalendarCalculator.trainedDayCount(inMonthOf: date(2026, 6, 10), from: [e]) == 2)
    }

    @Test
    func testTrainedDayCountIncludesMonthBoundaryDays() {
        let e = makeEntry(name: "Pecho", dates: [date(2026, 6, 1), date(2026, 6, 30)])
        #expect(MonthCalendarCalculator.trainedDayCount(inMonthOf: date(2026, 6, 15), from: [e]) == 2)
    }

    @Test
    func testTrainedDayCountExcludesFirstOfNextMonth() {
        // Regression: the 1st of the next month must NOT count toward this month
        // (DateInterval.contains is end-inclusive — this guards against that).
        let e = makeEntry(name: "Pecho", dates: [date(2026, 5, 20), date(2026, 6, 1)])
        #expect(MonthCalendarCalculator.trainedDayCount(inMonthOf: date(2026, 5, 10), from: [e]) == 1)
    }

    // MARK: - weekBreakdown
    // (Week of June 10 2026 = Mon June 8 … Sun June 14.)

    @Test
    func testWeekBreakdownGroupsByDayAndExcludesOtherWeeks() {
        let pecho = makeEntry(name: "Pecho", dates: [date(2026, 6, 8), date(2026, 6, 12)])
        let yoga = makeEntry(name: "Yoga", dates: [date(2026, 6, 8)])
        let nextWeek = makeEntry(name: "Espalda", dates: [date(2026, 6, 16)])

        let result = MonthCalendarCalculator.weekBreakdown(forWeekContaining: date(2026, 6, 10), from: [pecho, yoga, nextWeek])
        let cal = Date.appCalendar

        #expect(result.count == 2)
        #expect(cal.component(.day, from: result[0].date) == 8)
        #expect(result[0].activities.map(\.entry.name) == ["Pecho", "Yoga"]) // sorted by name
        #expect(cal.component(.day, from: result[1].date) == 12)
        #expect(result[1].activities.map(\.entry.name) == ["Pecho"])
    }

    @Test
    func testWeekBreakdownUsesThatDaysWeightNotLatest() {
        // Same muscle, different weight each day → each row shows its own day's load.
        let pecho = MuscleEntry(name: "Pecho")
        pecho.addSession(date(2026, 6, 8), weight: 50)
        pecho.addSession(date(2026, 6, 12), weight: 80)
        let result = MonthCalendarCalculator.weekBreakdown(forWeekContaining: date(2026, 6, 10), from: [pecho])
        #expect(result[0].activities.first?.weightKg == 50) // Mon 8
        #expect(result[1].activities.first?.weightKg == 80) // Fri 12
    }

    @Test
    func testWeekBreakdownDaysAscending() {
        let e = makeEntry(name: "Pecho", dates: [date(2026, 6, 12), date(2026, 6, 8)])
        let result = MonthCalendarCalculator.weekBreakdown(forWeekContaining: date(2026, 6, 10), from: [e])
        #expect(result.map { Date.appCalendar.component(.day, from: $0.date) } == [8, 12])
    }

    @Test
    func testWeekBreakdownEmptyWhenNoActivity() {
        #expect(MonthCalendarCalculator.weekBreakdown(forWeekContaining: date(2026, 6, 10), from: []).isEmpty)
    }

    @Test
    func testWeekBreakdownIncludesDaysAcrossMonthBoundary() {
        // Week of July 1 2026 (Wed) = Mon June 29 … Sun July 5; entries on both sides.
        let june = makeEntry(name: "Pecho", dates: [date(2026, 6, 29)])
        let july = makeEntry(name: "Espalda", dates: [date(2026, 7, 2)])
        let result = MonthCalendarCalculator.weekBreakdown(forWeekContaining: date(2026, 7, 1), from: [june, july])
        #expect(result.count == 2)
    }

    // MARK: - weekdaySymbols

    @Test
    func testWeekdaySymbolsAreMondayFirst() {
        let symbols = MonthCalendarCalculator.weekdaySymbols()
        #expect(symbols.count == 7)
        #expect(symbols.first == Date.appCalendar.veryShortStandaloneWeekdaySymbols[1]) // Monday
    }
}
