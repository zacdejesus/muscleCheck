//
//  StatsViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var weeklyData: [(weekLabel: String, count: Int)] = []
    @Published var muscleFrequency: [(muscle: String, count: Int)] = []
    @Published var totalDaysTrained: Int = 0
    @Published var averageDaysPerWeek: Double = 0

    func update(with entries: [MuscleEntry]) {
        weeklyData = StatsCalculator.daysTrainedPerWeek(from: entries)
        muscleFrequency = StatsCalculator.frequencyByMuscle(from: entries)
        totalDaysTrained = StatsCalculator.totalDaysTrained(from: entries)
        averageDaysPerWeek = StatsCalculator.averageTrainingDaysPerWeek(from: entries)
    }
}
