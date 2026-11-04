//
//  CoachHistory.swift
//  MuscleCheck
//
//  Recent training history of the eligible gym groups, for the AI Coach prompt when
//  it runs on Private Cloud Compute. The server model uses it to choose between
//  coherent pairs and to explain the choice; the hard rotation rule still lives in
//  WorkoutEligibility. The on-device model never gets it: there, history only made
//  the answers worse and tripped its guardrails (docs/feature12-prompt-tuning.md).
//
//  Returns data, not text: the localized wording lives with the prompts in
//  LocalizedStrings. No FoundationModels here on purpose — plain, testable logic (iOS 18+).
//

import Foundation

struct CoachHistory {

    /// How far back the model sees, in calendar days. Older sessions don't count.
    static let windowDays = 28

    struct Line: Equatable {
        /// Position in the group list handed to the model — the index it answers with.
        let index: Int
        let name: String
        /// Calendar days since the last session; `nil` when not trained within the window.
        let daysSinceLast: Int?
        let sessionsInWindow: Int
    }

    /// One line per group, in the given order, so each line's index matches the
    /// numbered list the model picks from.
    static func lines(for groups: [MuscleEntry], today: Date = Date()) -> [Line] {
        let calendar = Date.appCalendar
        let todayStart = calendar.startOfDay(for: today)

        return groups.enumerated().map { index, entry in
            let sessionsInWindow = entry.sessions.filter { session in
                let days = calendar.dateComponents(
                    [.day], from: calendar.startOfDay(for: session.date), to: todayStart
                ).day ?? .max
                return (0..<windowDays).contains(days)
            }.count

            let daysSinceLast = WorkoutEligibility.restDaysSinceLastSession(entry, today: today)
                .flatMap { $0 < windowDays ? $0 : nil }

            return Line(
                index: index,
                name: entry.name,
                daysSinceLast: daysSinceLast,
                sessionsInWindow: sessionsInWindow
            )
        }
    }
}
