//
//  OnboardingViewModel.swift
//  MuscleCheck
//
//  First-run onboarding: the user picks their disciplines and the initial checklist
//  is seeded from their presets (instead of the old always-gym seed).
//

import Foundation
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {

    /// Gym starts selected: it's the most common discipline and gives "Skip" and
    /// "Continue" the same default outcome.
    @Published var selectedCategories: Set<ActivityCategory> = [.gym]

    /// Built-ins offered in the picker. `.custom` is a resolver fallback for orphaned
    /// entries, not a discipline the user would choose.
    let selectableCategories = ActivityCategory.allCases.filter { $0 != .custom }

    var canContinue: Bool { !selectedCategories.isEmpty }

    private let analytics: any AnalyticsTracking
    /// `onAppear` puede volver a dispararse: el inicio del funnel se cuenta una vez.
    private var didTrackStart = false

    init(analytics: any AnalyticsTracking = AnalyticsService.shared) {
        self.analytics = analytics
    }

    func trackStarted() {
        guard !didTrackStart else { return }
        didTrackStart = true
        analytics.track(.onboardingStarted)
    }

    func toggle(_ category: ActivityCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func completeOnboarding(context: ModelContextProtocol) {
        seed(selectedCategories, context: context)
        analytics.track(.onboardingCompleted(seedCount: selectedCategories.count, skipped: false))
    }

    /// Skipping keeps parity with the pre-onboarding behavior: a gym checklist.
    func skipOnboarding(context: ModelContextProtocol) {
        seed([.gym], context: context)
        analytics.track(.onboardingCompleted(seedCount: 1, skipped: true))
    }

    private func seed(_ categories: Set<ActivityCategory>, context: ModelContextProtocol) {
        let manager = MuscleEntryManager(context: context)
        for category in categories.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            // One failed category must not block finishing onboarding — presets can
            // be re-added any time from Settings → Activity Presets.
            try? manager.addPresetEntries(for: category)
        }

        // Mirror what Settings does when adding presets, so those categories show
        // their green check there.
        var presets = Set(UserDefaultsManager.shared.addedActivityPresets)
        presets.formUnion(categories.map(\.rawValue))
        UserDefaultsManager.shared.addedActivityPresets = Array(presets)

        // Both flags: completing onboarding IS the initial seed, and setting
        // hasCompletedOnboarding dismisses the cover (ContentView observes the key).
        UserDefaultsManager.shared.defaultEntriesCreated = true
        UserDefaultsManager.shared.hasCompletedOnboarding = true
    }
}
