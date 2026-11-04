//
//  AnalyticsEventTests.swift
//  MuscleCheckTests
//
//  The event → name + parameters mapping. GA4 drops what breaks its rules without an
//  error — the event simply never shows up — so the rules are pinned here.
//

import Testing
@testable import MuscleCheck
import Foundation

struct AnalyticsEventTests {

    static let allEvents: [AnalyticsEvent] = [
        .onboardingStarted,
        .onboardingCompleted(seedCount: 2, skipped: false),
        .activityChecked(category: ActivityCategory.gym.rawValue, metric: .strength, source: .app, secondsSinceOpen: 3),
        .exerciseAddStarted(source: .fab),
        .exerciseAddCompleted(category: ActivityCategory.yoga.rawValue, metric: .duration, fromPreset: true, count: 2),
        .coachGenerated(engine: .privateCloud, fallbackReason: nil, latencyMilliseconds: 2_100),
        .coachGenerated(engine: .onDevice, fallbackReason: .timeout, latencyMilliseconds: 8_900)
    ]

    @Test(arguments: allEvents)
    func namesAndParametersRespectGA4Rules(_ event: AnalyticsEvent) {
        let pattern = "^[a-z][a-z0-9_]*$"
        #expect(event.name.count <= 40)
        #expect(event.name.range(of: pattern, options: .regularExpression) != nil)
        // 25 per event including Firebase's automatic ones.
        #expect(event.parameters.count <= 20)
        for (key, value) in event.parameters {
            #expect(key.count <= 40)
            #expect(key.range(of: pattern, options: .regularExpression) != nil)
            #expect(value is String || value is Int)
        }
    }

    @Test
    func namesMatchThePlan() {
        #expect(AnalyticsEvent.onboardingStarted.name == "onboarding_started")
        #expect(AnalyticsEvent.onboardingCompleted(seedCount: 1, skipped: true).name == "onboarding_completed")
        #expect(AnalyticsEvent.activityChecked(category: "gym", metric: .none, source: .siri, secondsSinceOpen: nil).name == "activity_checked")
        #expect(AnalyticsEvent.exerciseAddStarted(source: .emptyState).name == "exercise_add_started")
        #expect(AnalyticsEvent.exerciseAddCompleted(category: "gym", metric: .none, fromPreset: false, count: 1).name == "exercise_add_completed")
        #expect(AnalyticsEvent.coachGenerated(engine: .onDevice, fallbackReason: nil, latencyMilliseconds: 0).name == "coach_generated")
    }

    @Test
    func customCategoryIdsNeverLeaveTheDevice() {
        let customID = UUID().uuidString
        let event = AnalyticsEvent.activityChecked(category: customID, metric: .none, source: .app, secondsSinceOpen: nil)

        #expect(event.parameters["category"] as? String == ActivityCategory.custom.rawValue)
        #expect(AnalyticsEvent.categoryParameter(ActivityCategory.running.rawValue) == ActivityCategory.running.rawValue)
    }

    @Test
    func activityCheckedLeavesUnknownTimeOut() {
        let event = AnalyticsEvent.activityChecked(category: "gym", metric: .strength, source: .healthkit, secondsSinceOpen: nil)

        #expect(event.parameters["metric"] as? String == "strength")
        #expect(event.parameters["source"] as? String == "healthkit")
        // Absent, not 0: a 0 would drag down the median that measures "2 seconds".
        #expect(event.parameters["seconds_since_open"] == nil)
    }

    @Test
    func booleansTravelAsIntegers() {
        let completed = AnalyticsEvent.onboardingCompleted(seedCount: 3, skipped: true)
        #expect(completed.parameters["skipped"] as? Int == 1)
        #expect(completed.parameters["seed_count"] as? Int == 3)

        let added = AnalyticsEvent.exerciseAddCompleted(category: "gym", metric: .strength, fromPreset: false, count: 2)
        #expect(added.parameters["from_preset"] as? Int == 0)
        #expect(added.parameters["count"] as? Int == 2)
    }

    @Test
    func uiTestRunsNeverReachRealAnalytics() throws {
        let suite = "AnalyticsEventTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(true, forKey: "uiTesting")

        #expect(AnalyticsService.make(defaults: defaults) is NoOpAnalytics)
    }

    // MARK: - coach_generated

    @Test
    func coachGeneratedSendsTheFallbackReasonOnlyWhenThereIsOne() {
        let pcc = AnalyticsEvent.coachGenerated(engine: .privateCloud, fallbackReason: nil, latencyMilliseconds: 2_100)
        #expect(pcc.parameters["engine"] as? String == "pcc")
        #expect(pcc.parameters["fallback_reason"] == nil)

        let fallback = AnalyticsEvent.coachGenerated(engine: .onDevice, fallbackReason: .quota, latencyMilliseconds: 3_000)
        #expect(fallback.parameters["engine"] as? String == "on_device")
        #expect(fallback.parameters["fallback_reason"] as? String == "quota")
    }

    @Test(arguments: [(0, "<2s"), (1_999, "<2s"), (2_000, "2-4s"), (5_999, "4-6s"), (6_000, ">6s"), (30_000, ">6s")])
    func coachLatencyIsBucketed(_ milliseconds: Int, _ bucket: String) {
        #expect(AnalyticsEvent.latencyBucket(milliseconds: milliseconds) == bucket)
    }
}
