//
//  MuscleCheckAI.swift
//  MuscleCheck
//
//  On-device AI Coach (Feature 12). FoundationModels-only, iOS 26+.
//  The model's job is deliberately narrow: from the *eligible* gym groups the code
//  hands it (rotation already resolved — see WorkoutEligibility), pick a coherent
//  pair + 3 example exercises each. See docs/feature12-prompt-tuning.md.
//

import Observation
import FoundationModels
import Foundation

/// Structured output for the AI day suggestion. Groups are referenced by index into
/// the numbered list we pass in the prompt — robust, no fuzzy name matching.
@available(iOS 26, *)
@Generable
struct WorkoutSuggestion {
    // Schema field descriptions are kept language-neutral (English). The OUTPUT language
    // is set by the instructions ("Answer in <lang>"); these only describe the fields.
    @Guide(description: "Short label for the day, e.g. 'Push', 'Pull', 'Legs'")
    var focus: String
    @Guide(description: "Exactly 2 muscle groups that are coherent to train together today", .count(2))
    var blocks: [WorkoutBlock]
    @Guide(description: "One short sentence explaining why this day is suggested")
    var rationale: String
}

@available(iOS 26, *)
@Generable
struct WorkoutBlock {
    @Guide(description: "Index of the chosen muscle group, from the numbered list provided")
    var groupIndex: Int
    @Guide(description: "Three exercises that specifically target that muscle group", .count(3))
    var exercises: [String]
}

@available(iOS 26, *)
enum RoutineSuggestionError: Error {
    /// The stream finished without producing any usable content.
    case noContent
    /// The model returned no valid (in-range) muscle group, so there's nothing to show.
    case noValidBlocks
}

@available(iOS 26, *)
@Observable
@MainActor
final class MuscleCheckAI {

    let session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: LocalizedStrings.coachInstructions)
    }

    /// Suggests one coherent training day (exactly 2 gym muscle groups + example
    /// exercises) from the already-filtered `eligible` groups. Resolves the model's
    /// group indices to the user's actual entries here, returning a version-agnostic
    /// `RoutineSuggestion` the rest of the app (iOS 18) can hold and cache.
    ///
    /// Streams the response: `onPartial` is invoked with progressively-filled
    /// snapshots so the UI can paint the suggestion as it generates instead of
    /// showing a bare spinner. The returned value is built from the final snapshot.
    func suggestWorkout(
        eligible: [MuscleEntry],
        onPartial: ((RoutineSuggestion) -> Void)? = nil
    ) async throws -> RoutineSuggestion {
        let numbered = eligible.enumerated()
            .map { "\($0.offset)=\($0.element.name)" }
            .joined(separator: ", ")

        let prompt = LocalizedStrings.coachPrompt(groups: numbered)

        var options = GenerationOptions()
        options.sampling = .random(probabilityThreshold: 0.9)
        options.temperature = 0.7
        options.maximumResponseTokens = 512

        let stream = session.streamResponse(
            to: prompt,
            generating: WorkoutSuggestion.self,
            options: options
        )

        var latest: WorkoutSuggestion.PartiallyGenerated?
        for try await partial in stream {
            latest = partial.content
            if let onPartial {
                onPartial(Self.resolve(partial.content, eligible: eligible))
            }
        }

        guard let latest else { throw RoutineSuggestionError.noContent }
        let result = Self.resolve(latest, eligible: eligible)
        guard !result.blocks.isEmpty else { throw RoutineSuggestionError.noValidBlocks }
        return result
    }

    /// Best-effort mapping of a (possibly partial) model snapshot to a
    /// `RoutineSuggestion`. Out-of-range/duplicate indices are dropped and counts
    /// capped by `WorkoutEligibility.resolveBlocks`.
    private static func resolve(
        _ partial: WorkoutSuggestion.PartiallyGenerated,
        eligible: [MuscleEntry]
    ) -> RoutineSuggestion {
        let raw: [(index: Int, exercises: [String])] = (partial.blocks ?? []).compactMap { block in
            guard let index = block.groupIndex else { return nil }
            return (index: index, exercises: block.exercises ?? [])
        }
        return RoutineSuggestion(
            focus: partial.focus ?? "",
            blocks: WorkoutEligibility.resolveBlocks(rawBlocks: raw, eligible: eligible),
            rationale: partial.rationale ?? ""
        )
    }

    func prewarmModel() {
        session.prewarm(promptPrefix: LocalizedStrings.promtPrefix)
    }

    /// Whether the on-device model can answer in the app's UI language. Apple
    /// Intelligence follows the SIRI language, not the device language — a phone in
    /// Spanish with Siri in English answers in English no matter what the prompt
    /// says. When this is false the coach modal shows a hint pointing at Settings.
    static func modelSupportsAppLanguage() -> Bool {
        guard let appLang = LocalizedStrings.appLanguage else { return true }
        return SystemLanguageModel.default.supportedLanguages.contains {
            $0.languageCode?.identifier == appLang
        }
    }

    func isAppleIntelligenceAvailable() -> Bool {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available: return true
        case .unavailable(.deviceNotEligible): return false
        case .unavailable(.appleIntelligenceNotEnabled): return false
        case .unavailable(.modelNotReady): return true
        case .unavailable(_): return false
        }
    }
}
