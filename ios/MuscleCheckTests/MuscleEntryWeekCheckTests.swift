//
//  MuscleEntryWeekCheckTests.swift
//  MuscleCheckTests — tech debt item 4: isChecked derived from sessions
//
//  Contract: `isChecked` is NOT stored state. It is the answer to "does this group
//  have any session inside the current week?", computed on read. Nothing writes it.
//
//  Product decision (2026-08-24): un-checking means "I did NOT train this this week",
//  so it removes every session of the CURRENT week (earlier weeks are history and
//  stay untouched). Anything less would leave the circle checked after the tap.
//
//  Week edges are pinned with fixed dates rather than "today" so the year-boundary
//  and Monday-first cases are actually reachable. Fixtures verified against
//  Date.appCalendar (gregorian, firstWeekday = 2):
//      sun 27/12/2026                   → last day of the week BEFORE the boundary week
//      mon 28/12/2026 … sun 03/01/2027  → one single week that crosses the year
//      mon 04/01/2027                   → first day of the NEXT week
//

import Testing
@testable import MuscleCheck
import Foundation

struct MuscleEntryWeekCheckTests {

    // MARK: - Helpers

    /// Noon-anchored date (dodges midnight/DST edges), built with the app calendar.
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour
        return Date.appCalendar.date(from: c)!
    }

    private func entry(sessions dates: [Date]) -> MuscleEntry {
        let e = MuscleEntry(name: "Piernas")
        for d in dates { e.addSession(d) }
        return e
    }

    /// A day inside the CURRENT week that is not today — "I trained on Monday,
    /// I'm un-checking on Wednesday" without depending on which day the test runs.
    private func otherDayInCurrentWeek() -> Date {
        let cal = Date.appCalendar
        let monday = Date().startOfWeek()!
        return cal.isDateInToday(monday) ? cal.date(byAdding: .day, value: 1, to: monday)! : monday
    }

    private var sundayBefore: Date { date(2026, 12, 27) }
    private var monday: Date       { date(2026, 12, 28) }
    private var thursday: Date     { date(2026, 12, 31) }
    private var friday: Date       { date(2027, 1, 1) }
    private var sunday: Date       { date(2027, 1, 3) }
    private var nextMonday: Date   { date(2027, 1, 4) }

    // MARK: - The derivation

    @Test
    func noSessionsIsNotTrained() {
        let e = entry(sessions: [])
        #expect(e.isTrained(inWeekOf: thursday) == false)
    }

    @Test
    func sessionOnTheSameDayIsTrained() {
        let e = entry(sessions: [thursday])
        #expect(e.isTrained(inWeekOf: thursday) == true)
    }

    /// The bug this whole refactor exists for: trained Monday, asking on Thursday.
    @Test
    func sessionEarlierInTheSameWeekIsTrained() {
        let e = entry(sessions: [monday])
        #expect(e.isTrained(inWeekOf: thursday) == true)
    }

    @Test
    func sessionInThePreviousWeekIsNotTrained() {
        let e = entry(sessions: [sundayBefore])
        #expect(e.isTrained(inWeekOf: thursday) == false)
    }

    @Test
    func sessionInTheFollowingWeekIsNotTrained() {
        let e = entry(sessions: [nextMonday])
        #expect(e.isTrained(inWeekOf: thursday) == false)
    }

    /// Fails the moment the implementation compares `weekOfYear` + `year` instead of
    /// asking the calendar: both dates are week 1, but calendar years 2026 and 2027.
    @Test
    func weekCrossingTheYearBoundaryCountsAsOneWeek() {
        let e = entry(sessions: [monday])                 // mon 28/12/2026
        #expect(e.isTrained(inWeekOf: friday) == true)    // fri 01/01/2027
    }

    /// Fails if the calendar ever loses `firstWeekday = 2`: with a Sunday-first
    /// calendar, sunday 03/01 would open a new week instead of closing this one.
    @Test
    func sundayBelongsToTheWeekThatStartedOnMonday() {
        let e = entry(sessions: [sunday])
        #expect(e.isTrained(inWeekOf: monday) == true)
        #expect(e.isTrained(inWeekOf: nextMonday) == false)
    }

    @Test
    func oneMatchingSessionAmongManyIsEnough() {
        let e = entry(sessions: [sundayBefore, monday, nextMonday])
        #expect(e.isTrained(inWeekOf: thursday) == true)
    }

    // MARK: - isChecked (the same thing, anchored to now)

    @Test
    func isCheckedIsTrueForASessionToday() {
        let e = entry(sessions: [Date()])
        #expect(e.isChecked == true)
    }

    @Test
    func isCheckedIsTrueForAnotherDayOfTheCurrentWeek() {
        let e = entry(sessions: [otherDayInCurrentWeek()])
        #expect(e.isChecked == true)
    }

    /// Exactly 7 days back is the same weekday one week earlier — always a different week.
    @Test
    func isCheckedIsFalseForLastWeek() {
        let lastWeek = Date.appCalendar.date(byAdding: .day, value: -7, to: Date())!
        let e = entry(sessions: [lastWeek])
        #expect(e.isChecked == false)
    }

    @Test
    func isCheckedIsFalseWithNoSessions() {
        #expect(entry(sessions: []).isChecked == false)
    }

    // MARK: - Un-checking

    @Test
    func removingClearsEverySessionOfThatWeek() {
        let e = entry(sessions: [monday, thursday, friday])
        e.removeSessions(inWeekOf: thursday)

        #expect(e.sessions.isEmpty)
        #expect(e.isTrained(inWeekOf: thursday) == false)
    }

    /// History is not collateral damage: un-checking this week must not erase
    /// what was recorded in earlier weeks.
    @Test
    func removingKeepsSessionsFromOtherWeeks() {
        let e = entry(sessions: [sundayBefore, monday, nextMonday])
        e.removeSessions(inWeekOf: thursday)

        #expect(e.sessions.count == 2)
        #expect(e.isTrained(inWeekOf: thursday) == false)
        #expect(e.isTrained(inWeekOf: sundayBefore) == true)
        #expect(e.isTrained(inWeekOf: nextMonday) == true)
    }

    @Test
    func removingIsIdempotent() {
        let e = entry(sessions: [monday])
        e.removeSessions(inWeekOf: thursday)
        e.removeSessions(inWeekOf: thursday)

        #expect(e.sessions.isEmpty)
    }

    @Test
    func removingWithNothingInThatWeekChangesNothing() {
        let e = entry(sessions: [sundayBefore])
        e.removeSessions(inWeekOf: thursday)

        #expect(e.sessions.count == 1)
    }

    // MARK: - The paths that used to set the flag by hand

    @Test
    func loggingASessionLeavesTheGroupChecked() {
        let e = MuscleEntry(name: "Pecho")
        e.setTodaySession(weight: 80, sets: 4, reps: 10)
        #expect(e.isChecked == true)
    }

    @Test
    func loggingAnExerciseLeavesTheGroupChecked() {
        let e = MuscleEntry(name: "Piernas", metric: .strength)
        let ex = e.addExercise(name: "Peso muerto", metric: .strength, icon: "figure.strengthtraining.traditional")
        e.logExercise(id: ex.id, input: SessionInput(weightKg: 100, sets: 3, reps: 8))

        #expect(e.isChecked == true)
    }

    @Test
    func addingAndRemovingTodayFlipsTheCheck() {
        let e = MuscleEntry(name: "Pecho")
        e.addSession(Date())
        #expect(e.isChecked == true)

        e.removeSession(matching: Date())
        #expect(e.isChecked == false)
    }
}
