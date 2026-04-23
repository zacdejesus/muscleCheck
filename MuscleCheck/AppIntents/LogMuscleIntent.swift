//
//  LogMuscleIntent.swift
//  MuscleCheck
//

import AppIntents

struct LogMuscleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Muscle Group"
    static var description = IntentDescription("Mark a muscle group as trained today")

    @Parameter(title: "Muscle Group", requestValueDialog: "Which muscle group did you train?")
    var muscle: MuscleAppEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let actor = MuscleDataActor(modelContainer: MuscleDataActor.sharedContainer)
        let message = try await actor.logMuscle(named: muscle.id)
        return .result(dialog: "\(message)")
    }
}
