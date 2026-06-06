//
//  WorkoutEligibility.swift
//  MuscleCheck
//
//  Pure rotation/eligibility logic for the AI Coach day suggestion (Feature 12).
//  The on-device model can't reason over history reliably, so the *code* decides
//  which gym groups are eligible today and the model only picks a coherent pair
//  from those. See docs/feature12-prompt-tuning.md for why.
//
//  No FoundationModels here on purpose — this is plain, testable logic (iOS 18+).
//

import Foundation

struct WorkoutEligibility {

    /// Gym muscle groups eligible to train today: those not trained within the last
    /// `restDays` days. With `restDays == 1` this excludes groups trained today or
    /// yesterday; groups never trained are always eligible.
    ///
    /// - Parameters:
    ///   - excluding: group names to drop (used by "dame otra" to force a different day).
    ///   - restDays: minimum rest, in calendar days, before a group is eligible again.
    ///   - today: injectable for testing.
    ///
    /// Fallback: if fewer than 2 groups remain after filtering, the rotation can't be
    /// honored (the user trained almost everything), so we return *all* gym groups,
    /// most-rested first, so the model always has a coherent pair to choose from.
    static func eligibleGymGroups(from entries: [MuscleEntry],
                                  excluding excluded: Set<String> = [],
                                  restDays: Int = 1,
                                  today: Date = Date()) -> [MuscleEntry] {
        let gym = entries.filter {
            $0.category == ActivityCategory.gym.rawValue && !$0.isDeleted
        }

        let eligible = gym.filter { entry in
            guard !excluded.contains(entry.name) else { return false }
            guard let rest = restDaysSinceLastSession(entry, today: today) else { return true }
            return rest > restDays
        }

        if eligible.count >= 2 { return eligible }

        // Not enough rested groups — offer all gym groups, most-rested first.
        return gym.sorted {
            (restDaysSinceLastSession($0, today: today) ?? .max) >
            (restDaysSinceLastSession($1, today: today) ?? .max)
        }
    }

    /// Maps the model's raw `(groupIndex, exercises)` pairs back onto the eligible
    /// groups, dropping out-of-range or duplicate indices, capping exercises at 3 and
    /// blocks at 2. Version-agnostic so it's testable without FoundationModels.
    static func resolveBlocks(rawBlocks: [(index: Int, exercises: [String])],
                              eligible: [MuscleEntry]) -> [RoutineSuggestion.Block] {
        var seenNames = Set<String>()
        var result: [RoutineSuggestion.Block] = []

        for raw in rawBlocks {
            guard eligible.indices.contains(raw.index) else { continue }
            let name = eligible[raw.index].name
            guard seenNames.insert(name).inserted else { continue }
            result.append(.init(groupName: name, exercises: Array(raw.exercises.prefix(3))))
            if result.count == 2 { break }
        }

        return result
    }

    /// Calendar-day distance from the group's most recent session to `today`.
    /// `nil` when the group was never trained.
    private static func restDaysSinceLastSession(_ entry: MuscleEntry, today: Date) -> Int? {
        guard let last = entry.sessions.map(\.date).max() else { return nil }
        let calendar = Date.appCalendar
        let from = calendar.startOfDay(for: last)
        let to = calendar.startOfDay(for: today)
        return calendar.dateComponents([.day], from: from, to: to).day
    }
}
