//
//  StreakCalculator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation

struct StreakCalculator {

    /// Returns unique training days extracted from all entries' activityDates, sorted descending.
    static func uniqueTrainingDays(from entries: [MuscleEntry]) -> [Date] {
        let calendar = Date.appCalendar
        var uniqueDays: [Date] = []

        for entry in entries {
            for date in entry.sessions.map(\.date) {
                let alreadyAdded = uniqueDays.contains {
                    calendar.isDate($0, inSameDayAs: date)
                }
                if !alreadyAdded {
                    uniqueDays.append(date)
                }
            }
        }

        return uniqueDays.sorted(by: >)
    }

    /// Start-of-week (Monday) dates that had ≥1 training day. The streak is measured in
    /// WEEKS, not days, because MuscleCheck is a weekly-cadence app — rest days are part of
    /// the plan and must not break the streak.
    static func trainedWeeks(from entries: [MuscleEntry]) -> Set<Date> {
        let calendar = Date.appCalendar
        var weeks: Set<Date> = []
        for entry in entries {
            for session in entry.sessions {
                if let weekStart = session.date.startOfWeek(using: calendar) {
                    weeks.insert(calendar.startOfDay(for: weekStart))
                }
            }
        }
        return weeks
    }

    /// Current streak in consecutive weeks with ≥1 training day, counting back from the
    /// current week. Stays alive through the in-progress week: it only drops to 0 once BOTH
    /// this week and last week have no training (the weekly analogue of "today or yesterday").
    static func currentStreak(from entries: [MuscleEntry], now: Date = Date()) -> Int {
        let calendar = Date.appCalendar
        let weeks = trainedWeeks(from: entries)
        guard !weeks.isEmpty,
              let thisWeek = now.startOfWeek(using: calendar).map({ calendar.startOfDay(for: $0) }),
              let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek) else {
            return 0
        }

        // The streak ends at this week if trained, else last week (grace), else it's dead.
        var cursor: Date
        if weeks.contains(thisWeek) {
            cursor = thisWeek
        } else if weeks.contains(lastWeek) {
            cursor = lastWeek
        } else {
            return 0
        }

        var streak = 0
        while weeks.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: prev)
        }
        return streak
    }

    /// Longest run of consecutive trained weeks across the whole history.
    static func maxStreak(from entries: [MuscleEntry]) -> Int {
        let calendar = Date.appCalendar
        let weeks = trainedWeeks(from: entries).sorted()
        guard !weeks.isEmpty else { return 0 }

        var maxRun = 1
        var run = 1
        for i in 1..<weeks.count {
            if let nextOfPrev = calendar.date(byAdding: .weekOfYear, value: 1, to: weeks[i - 1]),
               calendar.isDate(calendar.startOfDay(for: nextOfPrev), inSameDayAs: weeks[i]) {
                run += 1
                maxRun = max(maxRun, run)
            } else {
                run = 1
            }
        }
        return maxRun
    }

    /// Last date the user trained, nil if never.
    static func lastTrainedDate(from entries: [MuscleEntry]) -> Date? {
        uniqueTrainingDays(from: entries).first
    }
}
