//
//  StreakViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation

@MainActor
final class StreakViewModel: ObservableObject {
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var maxStreak: Int = 0
    @Published private(set) var lastTrainedDate: Date?

    func update(with entries: [MuscleEntry]) {
        currentStreak = StreakCalculator.currentStreak(from: entries)
        maxStreak = StreakCalculator.maxStreak(from: entries)
        lastTrainedDate = StreakCalculator.lastTrainedDate(from: entries)
    }

    /// The weekly streak is 0 exactly when neither this week nor last week has training,
    /// so a positive current streak means it's alive (drives the 🔥 vs 💤 icon).
    var isStreakAlive: Bool {
        currentStreak > 0
    }
}
