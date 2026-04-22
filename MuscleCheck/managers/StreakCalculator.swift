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
            for date in entry.activityDates {
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

    /// Current streak: consecutive days trained going backwards from today.
    static func currentStreak(from entries: [MuscleEntry]) -> Int {
        let calendar = Date.appCalendar
        let days = uniqueTrainingDays(from: entries)
        guard !days.isEmpty else { return 0 }

        // Streak is alive if trained today or yesterday
        let today = Date()
        let mostRecent = days[0]

        guard calendar.isDateInToday(mostRecent) ||
              calendar.isDateInYesterday(mostRecent) else {
            return 0
        }

        var streak = 1
        var previous = mostRecent

        for day in days.dropFirst() {
            guard let expectedPrev = calendar.date(byAdding: .day, value: -1, to: previous),
                  calendar.isDate(day, inSameDayAs: expectedPrev) else {
                break
            }
            streak += 1
            previous = day
        }

        _ = today // suppress warning
        return streak
    }

    /// Max streak ever achieved across all training history.
    static func maxStreak(from entries: [MuscleEntry]) -> Int {
        let calendar = Date.appCalendar
        let days = uniqueTrainingDays(from: entries)
        guard !days.isEmpty else { return 0 }

        var maxStreak = 1
        var current = 1
        var previous = days[0]

        for day in days.dropFirst() {
            guard let expectedPrev = calendar.date(byAdding: .day, value: -1, to: previous),
                  calendar.isDate(day, inSameDayAs: expectedPrev) else {
                current = 1
                previous = day
                continue
            }
            current += 1
            maxStreak = max(maxStreak, current)
            previous = day
        }

        return maxStreak
    }

    /// Last date the user trained, nil if never.
    static func lastTrainedDate(from entries: [MuscleEntry]) -> Date? {
        uniqueTrainingDays(from: entries).first
    }
}
