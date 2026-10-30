//
//  RoutineCoachViewModel.swift
//  MuscleCheck
//
//  AI Coach (Feature 12) — extracted from ContentViewModel, with which it shared
//  nothing but the entries array. Owns the suggestion, its streaming state and the
//  per-day cache. Entries are passed in per call rather than held, so there is no
//  second copy of the list to keep in sync.
//
//  Targets iOS 18: the model layer is reached through `RoutineSuggesting`, created in
//  `init` only on iOS 26+ (nil before, which hides the coach), and the suggestion is
//  kept as a version-agnostic `RoutineSuggestion`.
//

import Foundation

@MainActor
final class RoutineCoachViewModel: ObservableObject {

    /// Current suggested day, filled progressively while streaming.
    @Published var routineSuggestion: RoutineSuggestion?
    @Published var isGeneratingRoutine = false
    @Published var routineError: String?
    /// True when Apple Intelligence can't answer in the app's UI language (Siri
    /// language mismatch) — the modal shows a hint instead of silently answering
    /// in English on a Spanish phone.
    @Published private(set) var aiLanguageMismatch = false

    /// Groups from the last suggestion, excluded on "dame otra" to force a different day.
    private var lastSuggestedGroups: Set<String> = []

    /// nil below iOS 26, where FoundationModels doesn't exist.
    private let coach: RoutineSuggesting?

    /// - Parameter coach: injected by tests; defaults to `MuscleCheckAI` on iOS 26+.
    init(coach: RoutineSuggesting? = nil) {
        if let coach {
            self.coach = coach
        } else if #available(iOS 26, *) {
            self.coach = MuscleCheckAI()
        } else {
            self.coach = nil
        }
    }

    // MARK: - Lifecycle

    /// Warms the on-device model and restores today's cached suggestion, if any.
    func start() {
        coach?.prewarm()
        loadCachedRoutineIfToday()
    }

    func isAppleIntelligenceAvailable() -> Bool {
        coach?.isAppleIntelligenceAvailable ?? false
    }

    // MARK: - Generation

    /// Generates (or regenerates) a suggested training day from the eligible gym groups.
    /// Rotation/variety is resolved in code (`WorkoutEligibility`); the model only picks
    /// a coherent pair + example exercises. Free, on-device — no Pro gate.
    func generateRoutine(from entries: [MuscleEntry], regenerate: Bool = false) async {
        guard let coach else { return }

        let previous = routineSuggestion
        isGeneratingRoutine = true
        routineError = nil
        aiLanguageMismatch = !coach.supportsAppLanguage

        let excluded = regenerate ? lastSuggestedGroups : []
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, excluding: excluded)

        // Nothing to suggest from (no gym groups at all).
        guard eligible.count >= 2 else {
            isGeneratingRoutine = false
            routineError = String(localized: "ERROR_GENERATING_ROUTINE")
            return
        }

        do {
            let result = try await coach.suggestWorkout(eligible: eligible) { [weak self] partial in
                self?.routineSuggestion = partial
            }
            let suggestion = result.suggestion
            // The Siri-language hint is about the on-device model; PCC follows the prompt.
            if result.engine == .privateCloud { aiLanguageMismatch = false }
            routineSuggestion = suggestion
            lastSuggestedGroups = Set(suggestion.blocks.map(\.groupName))
            cacheRoutine(suggestion)
        } catch {
            routineError = String(localized: "ERROR_GENERATING_ROUTINE")
            routineSuggestion = previous // restore prior suggestion (nil on first run)
        }

        isGeneratingRoutine = false
    }

    // MARK: - Per-day cache

    private func cacheRoutine(_ suggestion: RoutineSuggestion) {
        guard let data = try? JSONEncoder().encode(suggestion) else { return }
        UserDefaultsManager.shared.cachedRoutineData = data
        UserDefaultsManager.shared.cachedRoutineDate = Date()
        UserDefaultsManager.shared.cachedRoutineLanguage = LocalizedStrings.appLanguage
    }

    private func loadCachedRoutineIfToday() {
        guard let date = UserDefaultsManager.shared.cachedRoutineDate,
              Date.appCalendar.isDate(date, inSameDayAs: Date()),
              // A cache from another language must not stick for the rest of the day
              // (e.g. generated in English before switching the phone to Spanish).
              UserDefaultsManager.shared.cachedRoutineLanguage == LocalizedStrings.appLanguage,
              let data = UserDefaultsManager.shared.cachedRoutineData,
              let cached = try? JSONDecoder().decode(RoutineSuggestion.self, from: data)
        else { return }
        routineSuggestion = cached
        lastSuggestedGroups = Set(cached.blocks.map(\.groupName))
    }
}
