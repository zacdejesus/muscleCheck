//
//  MuscleCheckAI.swift
//  MuscleCheck
//
//  AI Coach (Feature 12). FoundationModels-only, iOS 26+.
//  Rotation is always resolved in code first (WorkoutEligibility); the model only
//  picks a coherent pair from the eligible groups + 3 example exercises each.
//
//  Two engines (docs/feature12-prompt-tuning.md):
//  - Private Cloud Compute (iOS 27+): also gets each group's last-4-weeks history to
//    choose between coherent pairs and explain the choice, and copies each group's
//    name before its exercises. Better pairs and exercises, and faster in testing.
//  - On-device: the narrow prompt, no history (history tripped its guardrails and
//    made it worse). The fallback whenever PCC is unavailable, over quota, offline,
//    slow, or its answer fails our checks.
//

import FoundationModels
import Foundation

/// Structured output for the on-device day suggestion. Groups are referenced by index
/// into the numbered list we pass in the prompt — robust, no fuzzy name matching.
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

/// Structured output for the Private Cloud Compute day suggestion. Properties are
/// generated in declaration order, and the order is deliberate: the groups come
/// first so the focus describes the pick instead of steering it, and each block
/// copies the group's name right before its exercises so they're written for that
/// group (with custom names the model otherwise wrote leg exercises under "Upper body").
@available(iOS 26, *)
@Generable
struct CloudWorkoutSuggestion {
    @Guide(description: "Exactly 2 muscle groups that are coherent to train together today", .count(2))
    var blocks: [CloudWorkoutBlock]
    @Guide(description: "Short label for the day that describes the two chosen groups")
    var focus: String
    @Guide(description: "One short sentence explaining why this day is suggested")
    var rationale: String
}

@available(iOS 26, *)
@Generable
struct CloudWorkoutBlock {
    @Guide(description: "Index of the chosen muscle group, from the numbered list provided")
    var groupIndex: Int
    @Guide(description: "The chosen group's name, copied exactly as it appears in the list")
    var groupName: String
    @Guide(description: "Three exercises that train exactly what this group's name says", .count(3))
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
@MainActor
final class MuscleCheckAI: RoutineSuggesting {

    /// How long Private Cloud Compute gets before the on-device model takes over.
    /// Through this class PCC answered in 2.1–4.5 s in testing (on Wi-Fi, model and
    /// session created per request), so this leaves headroom for worse networks.
    /// Worst case with the fallback is this plus the on-device time (~3 s).
    static let privateCloudTimeout: Duration = .seconds(6)

    private static var generationOptions: GenerationOptions {
        var options = GenerationOptions()
        options.sampling = .random(probabilityThreshold: 0.9)
        options.temperature = 0.7
        options.maximumResponseTokens = 512
        return options
    }

    /// A fresh session per suggestion. One long-lived session kept every request and
    /// answer in its transcript: each "give me another" grew it toward the on-device
    /// context limit (4K tokens on most devices), and the instructions stayed in
    /// whatever language the app had at launch. Nothing needs the transcript —
    /// rotation and exclusions are resolved in code before each request.
    private func makeOnDeviceSession() -> LanguageModelSession {
        LanguageModelSession(instructions: LocalizedStrings.coachInstructions)
    }

    /// Suggests one coherent training day (exactly 2 gym muscle groups + example
    /// exercises) from the already-filtered `eligible` groups, on Private Cloud Compute
    /// when it can and on-device otherwise. Resolves the model's group indices to the
    /// user's actual entries, returning a version-agnostic `RoutineSuggestion` the rest
    /// of the app (iOS 18) can hold and cache.
    ///
    /// Only the on-device path streams `onPartial` snapshots. PCC answers whole: it's
    /// fast enough not to need it, and a half-painted PCC answer would otherwise be
    /// replaced mid-way by the on-device one when the fallback kicks in.
    func suggestWorkout(
        eligible: [MuscleEntry],
        onPartial: ((RoutineSuggestion) -> Void)? = nil
    ) async throws -> CoachResult {
        var fallbackReason: CoachFallbackReason?
        if #available(iOS 27, *) {
            do {
                let suggestion = try await suggestOnPrivateCloud(eligible: eligible)
                return CoachResult(suggestion: suggestion, engine: .privateCloud, fallbackReason: nil)
            } catch {
                fallbackReason = CoachFallbackReason(error)
            }
        }
        let suggestion = try await suggestOnDevice(eligible: eligible, onPartial: onPartial)
        return CoachResult(suggestion: suggestion, engine: .onDevice, fallbackReason: fallbackReason)
    }

    // MARK: - Private Cloud Compute

    /// Throws on anything that should hand over to the on-device model, including a
    /// `CoachFallbackReason` when PCC isn't tried at all.
    @available(iOS 27, *)
    private func suggestOnPrivateCloud(eligible: [MuscleEntry]) async throws -> RoutineSuggestion {
        // Checked per request: availability and quota change during the day.
        let model = PrivateCloudComputeLanguageModel()
        guard model.isAvailable else { throw CoachFallbackReason.unavailable }
        guard !model.quotaUsage.isLimitReached else { throw CoachFallbackReason.quota }

        // Built here, on the main actor: the request below only captures strings.
        let prompt = LocalizedStrings.cloudCoachPrompt(history: CoachHistory.lines(for: eligible))
        let answer = try await withTimeout(Self.privateCloudTimeout) {
            let session = LanguageModelSession(
                model: model, instructions: LocalizedStrings.cloudCoachInstructions
            )
            return try await session.respond(
                to: prompt, generating: CloudWorkoutSuggestion.self, options: Self.generationOptions
            ).content
        }

        // Drop blocks whose copied name disagrees with their index, then map by index.
        let names = eligible.map(\.name)
        let checked = answer.blocks.filter {
            WorkoutEligibility.echoedNameMatches($0.groupName, index: $0.groupIndex, eligibleNames: names)
        }
        let blocks = WorkoutEligibility.resolveBlocks(
            rawBlocks: checked.map { (index: $0.groupIndex, exercises: $0.exercises) },
            eligible: eligible
        )
        // Stricter than on-device: anything short of a full day is worth a second opinion.
        guard blocks.count == 2 else { throw RoutineSuggestionError.noValidBlocks }
        return RoutineSuggestion(focus: answer.focus, blocks: blocks, rationale: answer.rationale)
    }

    // MARK: - On-device

    /// Streams the response: `onPartial` is invoked with progressively-filled snapshots
    /// so the UI can paint the suggestion as it generates instead of showing a bare
    /// spinner. The returned value is built from the final snapshot.
    private func suggestOnDevice(
        eligible: [MuscleEntry],
        onPartial: ((RoutineSuggestion) -> Void)?
    ) async throws -> RoutineSuggestion {
        let numbered = eligible.enumerated()
            .map { "\($0.offset)=\($0.element.name)" }
            .joined(separator: ", ")

        let stream = makeOnDeviceSession().streamResponse(
            to: LocalizedStrings.coachPrompt(groups: numbered),
            generating: WorkoutSuggestion.self,
            options: Self.generationOptions
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

    /// Loads the on-device model ahead of the first request. It prewarms a throwaway
    /// session: the expensive part is loading the model, which the per-request
    /// sessions reuse. PCC needs no warm-up on our side.
    func prewarm() {
        makeOnDeviceSession().prewarm(promptPrefix: LocalizedStrings.promptPrefix)
    }

    /// Whether the on-device model can answer in the app's UI language. Apple
    /// Intelligence follows the SIRI language, not the device language — a phone in
    /// Spanish with Siri in English answers in English no matter what the prompt
    /// says. When this is false and the on-device model answered, the coach modal
    /// shows a hint pointing at Settings. PCC answered in the prompt's language in testing.
    var supportsAppLanguage: Bool {
        guard let appLang = LocalizedStrings.appLanguage else { return true }
        return SystemLanguageModel.default.supportedLanguages.contains {
            $0.languageCode?.identifier == appLang
        }
    }

    var isAppleIntelligenceAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available: return true
        case .unavailable(.deviceNotEligible): return false
        case .unavailable(.appleIntelligenceNotEnabled): return false
        case .unavailable(.modelNotReady): return true
        case .unavailable(_): return false
        }
    }
}
