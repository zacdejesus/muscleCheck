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
        let actor = try MuscleDataActor.makeActor()
        let outcome = try await actor.logMuscle(named: muscle.id)
        // Sin esto Siri es un agujero negro: quien registra solo por voz se lee como abandono.
        if let trained = outcome.newlyTrained {
            AnalyticsService.shared.track(.activityChecked(
                category: trained.category, metric: trained.metric,
                source: .siri, secondsSinceOpen: nil))
        }
        return .result(dialog: "\(outcome.message)")
    }
}
