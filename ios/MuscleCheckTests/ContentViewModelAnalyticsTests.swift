//
//  ContentViewModelAnalyticsTests.swift
//  MuscleCheckTests
//
//  What the home reports. `activity_checked` is the activation event of the whole funnel
//  (docs/analytics-plan.md §6), so what counts as one is pinned here.
//

import Testing
@testable import MuscleCheck
import Foundation

@MainActor
struct ContentViewModelAnalyticsTests {

    private func makeViewModel() -> (ContentViewModel, SpyAnalytics) {
        let spy = SpyAnalytics()
        let viewModel = ContentViewModel(context: MockContext(), analytics: spy, appVersion: "9.9.9")
        return (viewModel, spy)
    }

    @Test
    func checkingTracksOneActivityCheckedFromTheApp() {
        let (viewModel, spy) = makeViewModel()
        let entry = MuscleEntry(name: "Piernas")
        viewModel.markAppOpened(at: Date().addingTimeInterval(-5))

        viewModel.toggleActivity(for: entry)

        #expect(spy.events.count == 1)
        guard case let .activityChecked(category, metric, source, seconds)? = spy.events.first else {
            Issue.record("Expected activity_checked, got \(spy.events)")
            return
        }
        #expect(category == ActivityCategory.gym.rawValue)
        #expect(metric == .strength)
        #expect(source == .app)
        #expect((5...7).contains(seconds ?? -1))
    }

    @Test
    func uncheckingIsNotARegistration() {
        let (viewModel, spy) = makeViewModel()
        let entry = MuscleEntry(name: "Piernas")

        viewModel.toggleActivity(for: entry) // check
        viewModel.toggleActivity(for: entry) // uncheck

        #expect(spy.events.count == 1)
    }

    @Test
    func secondsSinceOpenIsLeftOutWhenTheOpenWasNeverSeen() {
        let (viewModel, spy) = makeViewModel()

        viewModel.toggleActivity(for: MuscleEntry(name: "Pecho"))

        guard case let .activityChecked(_, _, _, seconds)? = spy.events.first else {
            Issue.record("Expected activity_checked, got \(spy.events)")
            return
        }
        #expect(seconds == nil)
    }

    @Test
    func loggingAnExerciseCountsOnlyWhenItTrainsTheWeek() {
        let (viewModel, spy) = makeViewModel()
        let group = MuscleEntry(name: "Piernas")
        let exercise = group.addExercise(name: "Peso muerto", metric: .strength, icon: "dumbbell")

        viewModel.logExercise(exercise, SessionInput(weightKg: 100, sets: 3, reps: 5), in: group)
        viewModel.logExercise(exercise, SessionInput(weightKg: 105, sets: 3, reps: 5), in: group)

        #expect(spy.events.count == 1)
    }

    @Test
    func addStartedCarriesItsSource() {
        let (viewModel, spy) = makeViewModel()

        viewModel.trackAddStarted(from: .emptyState)

        #expect(spy.events == [.exerciseAddStarted(source: .emptyState)])
    }

    @Test
    func requestingAReviewRecordsTheVersionAndClearsThePending() {
        let (viewModel, _) = makeViewModel()
        let date = Date()

        viewModel.didRequestReview(at: date)

        #expect(UserDefaultsManager.shared.lastReviewRequestVersion == "9.9.9")
        let stored = try? #require(UserDefaultsManager.shared.lastReviewRequestDate)
        #expect(abs((stored ?? .distantPast).timeIntervalSince(date)) < 1)
        #expect(!viewModel.reviewRequestPending)
    }
}
