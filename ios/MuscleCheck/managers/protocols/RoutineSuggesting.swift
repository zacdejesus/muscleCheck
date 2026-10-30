//
//  RoutineSuggesting.swift
//  MuscleCheck
//
//  What the AI Coach view model needs from the model layer. `MuscleCheckAI`
//  (FoundationModels, iOS 26+) is the real implementation; tests inject a fake so the
//  view model's rules (errors, exclusions, cache) run without a model.
//

import Foundation

@MainActor
protocol RoutineSuggesting: AnyObject {
    /// Apple Intelligence is usable on this device (the coach button hides otherwise).
    var isAppleIntelligenceAvailable: Bool { get }
    /// The model can answer in the app's UI language (see `MuscleCheckAI`).
    var supportsAppLanguage: Bool { get }
    func prewarm()
    /// One suggested day from the already-eligible gym groups. `onPartial` receives
    /// progressively-filled snapshots while it generates.
    func suggestWorkout(
        eligible: [MuscleEntry],
        onPartial: ((RoutineSuggestion) -> Void)?
    ) async throws -> RoutineSuggestion
}
