//
//  MuscleCheckShortcuts.swift
//  MuscleCheck
//

import AppIntents

struct MuscleCheckShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMuscleIntent(),
            phrases: [
                "Log \(.applicationName)",
                "I trained \(\.$muscle) in \(.applicationName)"
            ],
            shortTitle: "Log Workout",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: GetWeeklyProgressIntent(),
            phrases: [
                "What did I train this week in \(.applicationName)"
            ],
            shortTitle: "Weekly Progress",
            systemImageName: "chart.bar"
        )
    }
}
