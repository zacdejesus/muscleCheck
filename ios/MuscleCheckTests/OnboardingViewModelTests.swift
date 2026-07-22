//
//  OnboardingViewModelTests.swift
//  MuscleCheckTests
//
//  First-run onboarding: selection state, preset seeding and flag migration.
//

import Testing
@testable import MuscleCheck
import Foundation

// Serialized: these tests contend on shared UserDefaults flags (onboarding/seed state).
@Suite(.serialized)
struct OnboardingViewModelTests {

    @MainActor
    private func resetFlags() {
        UserDefaultsManager.shared.hasCompletedOnboarding = false
        UserDefaultsManager.shared.defaultEntriesCreated = false
        UserDefaultsManager.shared.addedActivityPresets = []
    }

    @MainActor @Test
    func gymStartsSelectedAndCustomIsNotOffered() {
        let viewModel = OnboardingViewModel()

        #expect(viewModel.selectedCategories == [.gym])
        #expect(viewModel.canContinue)
        #expect(!viewModel.selectableCategories.contains(.custom))
    }

    @MainActor @Test
    func emptySelectionDisablesContinue() {
        let viewModel = OnboardingViewModel()

        viewModel.toggle(.gym)

        #expect(viewModel.selectedCategories.isEmpty)
        #expect(!viewModel.canContinue)
    }

    @MainActor @Test
    func completingSeedsPresetsForSelectedCategories() {
        resetFlags()
        let context = MockContext()
        let viewModel = OnboardingViewModel()

        viewModel.toggle(.yoga) // gym stays pre-selected → gym + yoga
        viewModel.completeOnboarding(context: context)

        let expected = ActivityCategory.gym.presetEntries.count + ActivityCategory.yoga.presetEntries.count
        #expect(context.inserted.count == expected)
        #expect(context.inserted.contains { $0.category == ActivityCategory.gym.rawValue })
        #expect(context.inserted.contains { $0.category == ActivityCategory.yoga.rawValue })
        #expect(context.saved)

        #expect(UserDefaultsManager.shared.hasCompletedOnboarding)
        #expect(UserDefaultsManager.shared.defaultEntriesCreated)
        #expect(Set(UserDefaultsManager.shared.addedActivityPresets)
            .isSuperset(of: [ActivityCategory.gym.rawValue, ActivityCategory.yoga.rawValue]))
    }

    @MainActor @Test
    func skipSeedsGymPresetsOnly() {
        resetFlags()
        let context = MockContext()
        let viewModel = OnboardingViewModel()

        viewModel.toggle(.yoga) // selection is ignored on skip
        viewModel.skipOnboarding(context: context)

        #expect(context.inserted.count == ActivityCategory.gym.presetEntries.count)
        #expect(context.inserted.allSatisfy { $0.category == ActivityCategory.gym.rawValue })
        #expect(UserDefaultsManager.shared.hasCompletedOnboarding)
        #expect(UserDefaultsManager.shared.defaultEntriesCreated)
    }

    @MainActor @Test
    func migrationMarksExistingUsersAsOnboarded() {
        UserDefaultsManager.shared.defaultEntriesCreated = true
        UserDefaultsManager.shared.hasCompletedOnboarding = false

        UserDefaultsManager.shared.migrateOnboardingFlagIfNeeded()

        #expect(UserDefaultsManager.shared.hasCompletedOnboarding)
    }

    @MainActor @Test
    func migrationLeavesNewInstallsPendingOnboarding() {
        UserDefaultsManager.shared.defaultEntriesCreated = false
        UserDefaultsManager.shared.hasCompletedOnboarding = false

        UserDefaultsManager.shared.migrateOnboardingFlagIfNeeded()

        #expect(!UserDefaultsManager.shared.hasCompletedOnboarding)
    }
}
