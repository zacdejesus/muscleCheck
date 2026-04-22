//
//  StatsCalculator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation

/// Stateless struct with pure functions for computing training statistics.
struct StatsCalculator {

    // MARK: - Weekly Training

    /// Returns the count of unique training days per calendar week for the last `numberOfWeeks` weeks.
    /// Result is ordered oldest → newest.
    static func daysTrainedPerWeek(from entries: [MuscleEntry], numberOfWeeks: Int = 8) -> [(weekLabel: String, count: Int)] {
        let calendar = Date.appCalendar
        let todayStart = calendar.startOfDay(for: Date())
        guard let currentWeekStart = todayStart.startOfWeek(using: calendar) else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var results: [(weekLabel: String, count: Int)] = []

        for offset in stride(from: -(numberOfWeeks - 1), through: 0, by: 1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else { continue }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }

            // Collect unique training days that fall within [weekStart, weekEnd]
            var uniqueDays: Set<String> = []
            for entry in entries {
                for date in entry.activityDates {
                    let dayStart = calendar.startOfDay(for: date)
                    if dayStart >= weekStart && dayStart <= weekEnd {
                        uniqueDays.insert(dayStart.description)
                    }
                }
            }

            let label = formatter.string(from: weekStart)
            results.append((weekLabel: label, count: uniqueDays.count))
        }

        return results
    }

    // MARK: - Muscle Frequency

    /// Returns total unique training days per muscle, sorted by count descending.
    static func frequencyByMuscle(from entries: [MuscleEntry]) -> [(muscle: String, count: Int)] {
        let calendar = Date.appCalendar
        return entries
            .map { entry in
                var uniqueDays: Set<String> = []
                for date in entry.activityDates {
                    uniqueDays.insert(calendar.startOfDay(for: date).description)
                }
                return (muscle: entry.name, count: uniqueDays.count)
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Summary Stats

    /// Total unique days trained across all history.
    static func totalDaysTrained(from entries: [MuscleEntry]) -> Int {
        StreakCalculator.uniqueTrainingDays(from: entries).count
    }

    /// Average unique training days per week over the last `numberOfWeeks` weeks.
    static func averageTrainingDaysPerWeek(from entries: [MuscleEntry], numberOfWeeks: Int = 8) -> Double {
        let weekly = daysTrainedPerWeek(from: entries, numberOfWeeks: numberOfWeeks)
        guard !weekly.isEmpty else { return 0 }
        let total = weekly.reduce(0) { $0 + $1.count }
        return Double(total) / Double(weekly.count)
    }
}
