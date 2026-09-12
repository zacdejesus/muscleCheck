//
//  SpyAnalytics.swift
//  MuscleCheckTests
//

@testable import MuscleCheck

/// Records every event instead of sending it — the analytics seam's test double.
final class SpyAnalytics: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }
}
