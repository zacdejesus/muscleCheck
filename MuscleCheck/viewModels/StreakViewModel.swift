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

    var isStreakAlive: Bool {
        guard let last = lastTrainedDate else { return false }
        let calendar = Date.appCalendar
        return calendar.isDateInToday(last) || calendar.isDateInYesterday(last)
    }
}
