//
//  CoachFallbackReasonTests.swift
//  MuscleCheckTests
//
//  The error → reason mapping is what analytics reports when the coach falls back
//  from Private Cloud Compute to the on-device model. The mapping needs the iOS 27
//  SDK types, and Swift Testing can't gate a @Test with @available, hence the guards.
//

import Testing
@testable import MuscleCheck
import FoundationModels

struct CoachFallbackReasonTests {

    @Test
    func privateCloudErrorsMapToTheirReason() {
        guard #available(iOS 27, *) else { return }
        typealias PCCError = PrivateCloudComputeLanguageModel.Error
        #expect(CoachFallbackReason(PCCError.networkFailure(.init(debugDescription: ""))) == .network)
        #expect(CoachFallbackReason(PCCError.quotaLimitReached(.init(debugDescription: ""))) == .quota)
        #expect(CoachFallbackReason(PCCError.serviceUnavailable(.init(debugDescription: ""))) == .service)
    }

    @Test
    func ourDeadlineIsATimeout() {
        guard #available(iOS 27, *) else { return }
        #expect(CoachFallbackReason(TimeoutError()) == .timeout)
    }

    @Test
    func answersThatFailOurChecksAreInvalid() {
        guard #available(iOS 27, *) else { return }
        #expect(CoachFallbackReason(RoutineSuggestionError.noContent) == .invalid)
        #expect(CoachFallbackReason(RoutineSuggestionError.noValidBlocks) == .invalid)
    }

    @Test
    func unknownErrorsAreOther() {
        guard #available(iOS 27, *) else { return }
        struct Unexpected: Error {}
        #expect(CoachFallbackReason(Unexpected()) == .other)
    }

    @Test
    func analyticsValuesAreStable() {
        // Sent as the `fallback_reason` analytics parameter: renaming breaks dashboards.
        #expect(CoachFallbackReason.allCases.map(\.rawValue) == [
            "unavailable", "quota", "network", "service", "timeout", "invalid", "rejected", "other"
        ])
    }
}
