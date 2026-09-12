//
//  ReviewPromptPolicyTests.swift
//  MuscleCheckTests
//
//  When the App Store review prompt is allowed. iOS caps it at 3 a year and may show
//  none, so every request spent too early is one that isn't there when it matters.
//

import Testing
@testable import MuscleCheck
import Foundation

struct ReviewPromptPolicyTests {

    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func daysAgo(_ days: Int) -> Date {
        Date.appCalendar.date(byAdding: .day, value: -days, to: now)!
    }

    @Test
    func oneWeekIsTooEarly() {
        #expect(!ReviewPromptPolicy.shouldRequest(
            currentStreak: 1, lastRequestDate: nil, lastRequestVersion: nil,
            currentVersion: "2.3.0", now: now))
    }

    @Test
    func twoWeeksInARowWithNoPreviousRequestAsks() {
        #expect(ReviewPromptPolicy.shouldRequest(
            currentStreak: 2, lastRequestDate: nil, lastRequestVersion: nil,
            currentVersion: "2.3.0", now: now))
    }

    @Test
    func neverTwiceInTheSameVersion() {
        #expect(!ReviewPromptPolicy.shouldRequest(
            currentStreak: 10, lastRequestDate: daysAgo(400), lastRequestVersion: "2.3.0",
            currentVersion: "2.3.0", now: now))
    }

    @Test
    func aNewVersionStillWaitsTheMinimumGap() {
        #expect(!ReviewPromptPolicy.shouldRequest(
            currentStreak: 10, lastRequestDate: daysAgo(30), lastRequestVersion: "2.2.1",
            currentVersion: "2.3.0", now: now))
    }

    @Test
    func aNewVersionAfterTheGapAsksAgain() {
        #expect(ReviewPromptPolicy.shouldRequest(
            currentStreak: 10, lastRequestDate: daysAgo(ReviewPromptPolicy.minimumDaysBetweenRequests + 1),
            lastRequestVersion: "2.2.1", currentVersion: "2.3.0", now: now))
    }
}
