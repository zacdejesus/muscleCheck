//
//  MonthCalendarCalculator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 13/06/2026.
//

import Foundation

/// One cell in the month grid. `isInDisplayedMonth` is false for the leading/trailing
/// days that belong to the adjacent month (rendered dimmed).
struct CalendarDay: Identifiable, Hashable {
    let date: Date
    let isInDisplayedMonth: Bool
    var id: Date { date }
}

/// One trained muscle on a given day, carrying THAT day's logged values (may be nil)
/// — not the entry's latest, so historical rows show what was actually done.
struct DayActivity: Identifiable {
    let entry: MuscleEntry
    let weightKg: Double?
    var durationSeconds: Int? = nil
    var distanceMeters: Double? = nil
    /// Exercises logged on this day (Fase 2). When present, the detail row shows
    /// these instead of the group's own (now value-less) session.
    var exercises: [ExerciseOnDay] = []
    var id: UUID { entry.id }
}

/// One exercise done on a given day, with that day's label ("Peso muerto · 100 kg").
struct ExerciseOnDay: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let summary: String?
}

/// The activities trained on a single day, used by the week detail breakdown.
struct DayActivities: Identifiable {
    let date: Date
    let activities: [DayActivity]
    var id: Date { date }
}

/// Stateless struct with pure functions for the history month calendar.
/// Mirrors `StatsCalculator`: uses `Date.appCalendar` directly (Monday-first).
struct MonthCalendarCalculator {

    // MARK: - Month grid

    /// A fixed 6×7 matrix of days for the month containing `monthAnchor`.
    /// Always 42 cells so the grid height never jumps when paging months; the
    /// leading/trailing days belong to the adjacent month (`isInDisplayedMonth == false`).
    static func monthMatrix(for monthAnchor: Date) -> [[CalendarDay]] {
        let calendar = Date.appCalendar
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor),
              // firstWeekday == 2, so startOfWeek lands on the Monday on/before day 1 —
              // this resolves the Monday-first leading offset for free.
              let gridStart = monthInterval.start.startOfWeek(using: calendar) else {
            return []
        }

        var days: [CalendarDay] = []
        days.reserveCapacity(42)
        for offset in 0..<42 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let inMonth = calendar.isDate(dayStart, equalTo: monthAnchor, toGranularity: .month)
            days.append(CalendarDay(date: dayStart, isInDisplayedMonth: inMonth))
        }

        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    /// The 7 days (Monday-first) of the week containing `date`, for the collapsed calendar.
    /// `isInDisplayedMonth` is relative to `date`'s month, so a week spanning a month
    /// boundary dims the spilled days — same convention as the full grid.
    static func weekRow(forWeekContaining date: Date) -> [CalendarDay] {
        let calendar = Date.appCalendar
        guard let monday = date.startOfWeek(using: calendar) else { return [] }
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let dayStart = calendar.startOfDay(for: day)
            let inMonth = calendar.isDate(dayStart, equalTo: date, toGranularity: .month)
            return CalendarDay(date: dayStart, isInDisplayedMonth: inMonth)
        }
    }

    /// Monday-first single-letter weekday headers, localized.
    static func weekdaySymbols() -> [String] {
        // `Date.appCalendar` is a bare gregorian calendar with no `locale`, so its
        // symbol arrays fall back to English regardless of the app's language. We set
        // an explicit locale ONLY here (not on `appCalendar`) so week-of-year math
        // elsewhere keeps its fixed firstWeekday/minimumDaysInFirstWeek behaviour.
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols // index 0 = Sunday
        let firstIndex = Date.appCalendar.firstWeekday - 1        // 1 → Monday-first
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    // MARK: - Training signals

    /// Set of start-of-day dates that had at least one session (O(1) membership for the grid).
    static func trainedDays(from entries: [MuscleEntry]) -> Set<Date> {
        let calendar = Date.appCalendar
        var set: Set<Date> = []
        for entry in entries {
            for session in entry.sessions {
                set.insert(calendar.startOfDay(for: session.date))
            }
        }
        return set
    }

    /// Number of distinct muscles trained per day (an entry trained twice the same day counts once).
    /// Drives the intensity of the calendar dot.
    static func muscleCountByDay(from entries: [MuscleEntry]) -> [Date: Int] {
        let calendar = Date.appCalendar
        var counts: [Date: Int] = [:]
        for entry in entries {
            var entryDays: Set<Date> = []
            for session in entry.sessions {
                entryDays.insert(calendar.startOfDay(for: session.date))
            }
            for day in entryDays {
                counts[day, default: 0] += 1
            }
        }
        return counts
    }

    /// Count of unique days trained within the month containing `monthAnchor`.
    /// New vs. Stats (all-time total + 8-week chart) and Streak (current/max) — a per-month figure.
    /// Uses same-month comparison (not `DateInterval.contains`, which is end-inclusive and
    /// would double-count the 1st of the next month).
    static func trainedDayCount(inMonthOf monthAnchor: Date, from entries: [MuscleEntry]) -> Int {
        let calendar = Date.appCalendar
        return trainedDays(from: entries)
            .filter { calendar.isDate($0, equalTo: monthAnchor, toGranularity: .month) }
            .count
    }

    // MARK: - Week detail

    /// Per-day breakdown of the week containing `date`: only days with ≥1 activity,
    /// ascending by date, entries sorted by name. Same week semantics as the old
    /// `groupedEntries` (`dateInterval(of: .weekOfYear)`).
    static func weekBreakdown(forWeekContaining date: Date, from entries: [MuscleEntry]) -> [DayActivities] {
        let calendar = Date.appCalendar
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }

        var result: [DayActivities] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let activities = entries
                .compactMap { entry -> DayActivity? in
                    guard let session = entry.sessions.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) else { return nil }
                    // Exercises logged that same day, with that day's values.
                    let exercisesThatDay: [ExerciseOnDay] = entry.exercises.compactMap { ex in
                        guard let s = ex.sessions.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) else { return nil }
                        return ExerciseOnDay(
                            id: ex.id,
                            name: ex.name,
                            icon: ex.icon,
                            summary: SessionFormatting.label(
                                metric: ex.metric, weightKg: s.weight,
                                durationSeconds: s.durationSeconds, distanceMeters: s.distanceMeters)
                        )
                    }
                    return DayActivity(
                        entry: entry,
                        weightKg: session.weight,
                        durationSeconds: session.durationSeconds,
                        distanceMeters: session.distanceMeters,
                        exercises: exercisesThatDay
                    )
                }
                .sorted { $0.entry.name < $1.entry.name }
            if !activities.isEmpty {
                result.append(DayActivities(date: dayStart, activities: activities))
            }
        }
        return result
    }
}
