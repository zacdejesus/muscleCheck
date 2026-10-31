//
//  RoutineCoachViewModelTests.swift
//  MuscleCheckTests
//
//  The coach view model's rules, with a fake model layer: what it hands the model,
//  what it keeps when the model fails, and when it doesn't call it at all.
//

import Testing
@testable import MuscleCheck
import Foundation

// Serialized: generation writes the per-day cache in the shared UserDefaults.
@MainActor
@Suite(.serialized)
struct RoutineCoachViewModelTests {

    init() {
        UserDefaultsManager.shared.cachedRoutineData = nil
        UserDefaultsManager.shared.cachedRoutineDate = nil
    }

    // MARK: - Fixtures

    private func gymEntry(_ name: String, daysAgo: [Int] = []) -> MuscleEntry {
        let entry = MuscleEntry(name: name, category: ActivityCategory.gym.rawValue)
        for day in daysAgo {
            if let date = Date.appCalendar.date(byAdding: .day, value: -day, to: Date()) {
                entry.addSession(date)
            }
        }
        return entry
    }

    private func suggestion(_ first: String, _ second: String) -> RoutineSuggestion {
        RoutineSuggestion(
            focus: "Pull",
            blocks: [.init(groupName: first, exercises: ["A"]), .init(groupName: second, exercises: ["B"])],
            rationale: "Because."
        )
    }

    // MARK: - Tests

    @Test
    func generatesFromTheEligibleGroupsAndKeepsTheResult() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())
        let entries = [gymEntry("Chest", daysAgo: [1]), gymEntry("Back"), gymEntry("Biceps")]

        await viewModel.generateRoutine(from: entries)

        #expect(coach.receivedEligible == [["Back", "Biceps"]])
        #expect(viewModel.routineSuggestion == suggestion("Back", "Biceps"))
        #expect(viewModel.routineError == nil)
        #expect(!viewModel.isGeneratingRoutine)
    }

    @Test
    func giveMeAnotherExcludesTheLastSuggestedGroups() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())
        let entries = ["Back", "Biceps", "Legs", "Abs"].map { gymEntry($0) }

        await viewModel.generateRoutine(from: entries)
        await viewModel.generateRoutine(from: entries, regenerate: true)

        #expect(coach.receivedEligible.last == ["Legs", "Abs"])
    }

    @Test
    func giveMeAnotherWithNoOtherPairKeepsTheDayWithoutAskingTheModel() async {
        // Excluding Back + Biceps leaves only Legs, trained yesterday: nothing else today.
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())
        let entries = [gymEntry("Back"), gymEntry("Biceps"), gymEntry("Legs", daysAgo: [1])]
        await viewModel.generateRoutine(from: entries)

        await viewModel.generateRoutine(from: entries, regenerate: true)

        #expect(viewModel.noOtherOption)
        #expect(viewModel.routineSuggestion == suggestion("Back", "Biceps"))
        #expect(coach.receivedEligible.count == 1)
    }

    @Test
    func giveMeAnotherWithAnotherPairClearsTheNotice() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())
        let few = [gymEntry("Back"), gymEntry("Biceps"), gymEntry("Legs", daysAgo: [1])]
        await viewModel.generateRoutine(from: few)
        await viewModel.generateRoutine(from: few, regenerate: true)
        #expect(viewModel.noOtherOption)

        // A new group shows up (e.g. Legs is now rested): another pair exists again.
        let more = few + [gymEntry("Chest"), gymEntry("Triceps")]
        await viewModel.generateRoutine(from: more, regenerate: true)

        #expect(!viewModel.noOtherOption)
        #expect(coach.receivedEligible.count == 2)
    }

    @Test
    func aFailedRequestKeepsThePreviousSuggestion() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())
        let entries = ["Back", "Biceps", "Legs", "Abs"].map { gymEntry($0) }
        await viewModel.generateRoutine(from: entries)

        coach.result = .failure(FakeCoach.Failure())
        await viewModel.generateRoutine(from: entries, regenerate: true)

        #expect(viewModel.routineSuggestion == suggestion("Back", "Biceps"))
        #expect(viewModel.routineError != nil)
    }

    @Test
    func doesNotCallTheModelWithFewerThanTwoGymGroups() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())

        await viewModel.generateRoutine(from: [gymEntry("Back")])

        #expect(coach.receivedEligible.isEmpty)
        #expect(viewModel.routineError != nil)
    }

    @Test
    func flagsALanguageTheModelCannotAnswerIn() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        coach.supportsAppLanguage = false
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())

        await viewModel.generateRoutine(from: ["Back", "Biceps"].map { gymEntry($0) })

        #expect(viewModel.aiLanguageMismatch)
    }

    @Test
    func noLanguageHintWhenPrivateCloudAnswered() async {
        // The hint explains the on-device model following Siri's language; PCC follows the prompt.
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        coach.supportsAppLanguage = false
        coach.engine = .privateCloud
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics())

        await viewModel.generateRoutine(from: ["Back", "Biceps"].map { gymEntry($0) })

        #expect(!viewModel.aiLanguageMismatch)
    }

    @Test
    func tracksWhichModelGeneratedTheSuggestion() async {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        coach.engine = .privateCloud
        let analytics = SpyAnalytics()
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: analytics)

        await viewModel.generateRoutine(from: ["Back", "Biceps"].map { gymEntry($0) })

        guard case let .coachGenerated(engine, fallbackReason, _)? = analytics.events.last else {
            Issue.record("expected coach_generated, got \(analytics.events)")
            return
        }
        #expect(engine == .privateCloud)
        #expect(fallbackReason == nil)
    }

    @Test
    func tracksNothingWhenNoSuggestionCameOut() async {
        let coach = FakeCoach(result: .failure(FakeCoach.Failure()))
        let analytics = SpyAnalytics()
        let viewModel = RoutineCoachViewModel(coach: coach, analytics: analytics)

        await viewModel.generateRoutine(from: ["Back", "Biceps"].map { gymEntry($0) })

        #expect(analytics.events.isEmpty)
    }

    @Test
    func availabilityComesFromTheModelLayer() {
        let coach = FakeCoach(result: .success(suggestion("Back", "Biceps")))
        coach.isAppleIntelligenceAvailable = false
        #expect(!RoutineCoachViewModel(coach: coach, analytics: SpyAnalytics()).isAppleIntelligenceAvailable())
    }
}

// MARK: - Fake

@MainActor
private final class FakeCoach: RoutineSuggesting {
    struct Failure: Error {}

    var result: Result<RoutineSuggestion, Error>
    var isAppleIntelligenceAvailable = true
    var supportsAppLanguage = true
    /// Names of the eligible groups handed over on each call, in order.
    private(set) var receivedEligible: [[String]] = []

    init(result: Result<RoutineSuggestion, Error>) {
        self.result = result
    }

    func prewarm() {}

    var engine: CoachEngine = .onDevice

    func suggestWorkout(
        eligible: [MuscleEntry],
        onPartial: ((RoutineSuggestion) -> Void)?
    ) async throws -> CoachResult {
        receivedEligible.append(eligible.map(\.name))
        return CoachResult(suggestion: try result.get(), engine: engine, fallbackReason: nil)
    }
}
