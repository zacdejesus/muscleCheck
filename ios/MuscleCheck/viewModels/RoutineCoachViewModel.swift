//
//  RoutineCoachViewModel.swift
//  MuscleCheck
//
//  AI Coach (Feature 12) — extracted from ContentViewModel, with which it shared
//  nothing but the entries array. Owns the suggestion, its streaming state and the
//  per-day cache. Entries are passed in per call rather than held, so there is no
//  second copy of the list to keep in sync.
//
//  Targets iOS 18: FoundationModels (iOS 26+) is reached only through the availability
//  -gated `muscleCheckAI` accessor, and the suggestion is kept as a version-agnostic
//  `RoutineSuggestion`.
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

    /// Backing storage for the on-device AI. Held as `Any?` because `MuscleCheckAI`
    /// (FoundationModels) is only available on iOS 26+, while this view model targets iOS 18.
    private var aiStorage: Any?

    @available(iOS 26, *)
    private var muscleCheckAI: MuscleCheckAI {
        if let existing = aiStorage as? MuscleCheckAI { return existing }
        let new = MuscleCheckAI()
        aiStorage = new
        return new
    }

    // MARK: - Lifecycle

    /// Warms the on-device model and restores today's cached suggestion, if any.
    func start() {
        if #available(iOS 26, *) {
            muscleCheckAI.prewarmModel()
        }
        loadCachedRoutineIfToday()
    }

    func isAppleIntelligenceAvailable() -> Bool {
        guard #available(iOS 26, *) else { return false }
        return muscleCheckAI.isAppleIntelligenceAvailable()
    }

    // MARK: - Generation

    /// Generates (or regenerates) a suggested training day from the eligible gym groups.
    /// Rotation/variety is resolved in code (`WorkoutEligibility`); the model only picks
    /// a coherent pair + example exercises. Free, on-device — no Pro gate.
    func generateRoutine(from entries: [MuscleEntry], regenerate: Bool = false) async {
        guard #available(iOS 26, *) else { return }

        let previous = routineSuggestion
        isGeneratingRoutine = true
        routineError = nil
        aiLanguageMismatch = !MuscleCheckAI.modelSupportsAppLanguage()

        let excluded = regenerate ? lastSuggestedGroups : []
        let eligible = WorkoutEligibility.eligibleGymGroups(from: entries, excluding: excluded)

        // Nothing to suggest from (no gym groups at all).
        guard eligible.count >= 2 else {
            isGeneratingRoutine = false
            routineError = String(localized: "ERROR_GENERATING_ROUTINE")
            return
        }

        do {
            let suggestion = try await muscleCheckAI.suggestWorkout(eligible: eligible) { [weak self] partial in
                self?.routineSuggestion = partial
            }
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
