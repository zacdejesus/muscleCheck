//
//  GetWeeklyProgressIntent.swift
//  MuscleCheck
//

import AppIntents

struct GetWeeklyProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Weekly Training Progress"
    static var description = IntentDescription("See which muscles you trained this week")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let actor = MuscleDataActor(modelContainer: MuscleDataActor.sharedContainer)
        let checkedMuscles = try await actor.getWeeklyProgress()

        let message: String
        if checkedMuscles.isEmpty {
            message = String(localized: "intent_no_training_this_week")
        } else {
            let list = checkedMuscles.joined(separator: ", ")
            message = String(localized: "intent_weekly_progress \(list)")
        }

        return .result(dialog: "\(message)")
    }
}
