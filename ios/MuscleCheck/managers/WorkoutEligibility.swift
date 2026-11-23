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
        // One group per muscle: with "Chest" and "Pecho" both eligible the model could offer
        // them as a "coherent pair". The survivor is the one in use, so its last session is the
        // muscle's latest — rest is judged on the muscle, not on one of its names.
        let gym = GroupRanking.onePerMuscle(entries.filter {
            $0.category == ActivityCategory.gym.rawValue && !$0.isDeleted
        })

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

    /// The groups of today's training day, chosen in code: the day (push, pull, legs — the
    /// coach instructions' table) of the most rested group whose day has at least 2 groups in
    /// the list. Never trained counts as most rested; ties keep the input order. Returned most
    /// rested first.
    ///
    /// The on-device model doesn't choose a day: it takes the first day of the instructions'
    /// table that has groups (push whenever any push group is listed, 45/45 with a legs pair
    /// available), and pairs across days when that one has a single group. Handing it one
    /// day leaves it the part it does well: two groups and their exercises.
    ///
    /// Free-form and combined names ("Upper body", "Chest & triceps") have no day. When no
    /// day has 2 groups, the whole list is returned, most rested first, as before.
    static func groupsForToday(_ eligible: [MuscleEntry], today: Date = Date()) -> [MuscleEntry] {
        let rested = eligible.enumerated().sorted { a, b in
            let x = restDaysSinceLastSession(a.element, today: today) ?? .max
            let y = restDaysSinceLastSession(b.element, today: today) ?? .max
            return x != y ? x > y : a.offset < b.offset
        }.map(\.element)

        let days = rested.map { TargetMuscle.single(inName: $0.name)?.trainingDay }
        var count: [TrainingDay: Int] = [:]
        for case let day? in days { count[day, default: 0] += 1 }
        guard let day = days.lazy.compactMap({ $0 }).first(where: { count[$0, default: 0] >= 2 }) else {
            return rested
        }
        return zip(rested, days).filter { $0.1 == day }.map(\.0)
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

    /// Whether the group name the model copied into its answer matches the group at
    /// the index it picked. The Private Cloud Compute coach writes the name right
    /// before the exercises so they're written for that group; this catches the
    /// answers where index and name disagree.
    ///
    /// Tolerant of case, accents, spacing and trailing noise ("Legs: legs/abs" for
    /// "Legs"), but the copied name must not be a better match for another group:
    /// "Chest & triceps" under the index of "Chest" fails when both are listed.
    static func echoedNameMatches(_ echoed: String, index: Int, eligibleNames: [String]) -> Bool {
        guard eligibleNames.indices.contains(index) else { return false }
        let echo = normalized(echoed)
        // Every listed group the echo could be naming; the longest one is what it names.
        let named = eligibleNames.indices
            .filter { isPrefixName(normalized(eligibleNames[$0]), of: echo) }
            .max { normalized(eligibleNames[$0]).count < normalized(eligibleNames[$1]).count }
        return named.map { normalized(eligibleNames[$0]) == normalized(eligibleNames[index]) } ?? false
    }

    /// `name` equals `echo`, or starts it and is followed by a non-alphanumeric
    /// character — so "Legs" matches "Legs: legs/abs" but "Arm" doesn't match "Arms".
    private static func isPrefixName(_ name: String, of echo: String) -> Bool {
        guard !name.isEmpty, echo.hasPrefix(name) else { return false }
        guard let next = echo.dropFirst(name.count).first else { return true }
        return !(next.isLetter || next.isNumber)
    }

    private static func normalized(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Calendar-day distance from the group's most recent session to `today`.
    /// `nil` when the group was never trained. Shared with `CoachHistory`.
    static func restDaysSinceLastSession(_ entry: MuscleEntry, today: Date) -> Int? {
        guard let last = entry.sessions.map(\.date).max() else { return nil }
        let calendar = Date.appCalendar
        let from = calendar.startOfDay(for: last)
        let to = calendar.startOfDay(for: today)
        return calendar.dateComponents([.day], from: from, to: to).day
    }
}

/// The days the coach instructions describe: push (chest/shoulders/triceps), pull
/// (back/biceps), legs (legs/abs). Calves, glutes and forearms join the day they're usually
/// trained with.
enum TrainingDay: Sendable {
    case push, pull, legs
}

extension TargetMuscle {
    var trainingDay: TrainingDay {
        switch self {
        case .chest, .shoulders, .triceps: return .push
        case .back, .biceps, .forearms: return .pull
        case .legs, .glutes, .calves, .core: return .legs
        }
    }
}
