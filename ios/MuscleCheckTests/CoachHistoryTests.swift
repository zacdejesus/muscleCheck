//
//  CoachHistoryTests.swift
//  MuscleCheckTests
//
//  Covers the history the AI Coach hands the Private Cloud Compute model: the
//  4-week window, the per-line index the model answers with, and the session count.
//

import Testing
@testable import MuscleCheck
import Foundation

struct CoachHistoryTests {

    private let today = Date()

    private func makeEntry(_ name: String, daysAgo: [Int] = []) -> MuscleEntry {
        let entry = MuscleEntry(name: name, category: ActivityCategory.gym.rawValue)
        for day in daysAgo {
            if let date = Date.appCalendar.date(byAdding: .day, value: -day, to: today) {
                entry.addSession(date)
            }
        }
        return entry
    }

    @Test
    func neverTrainedGroupHasNoLastSessionAndZeroCount() {
        let lines = CoachHistory.lines(for: [makeEntry("Pecho")], today: today)
        #expect(lines == [.init(index: 0, name: "Pecho", daysSinceLast: nil, sessionsInWindow: 0)])
    }

    @Test
    func lastSessionIsTheMostRecentOne() {
        let lines = CoachHistory.lines(for: [makeEntry("Piernas", daysAgo: [12, 1, 6])], today: today)
        #expect(lines.first?.daysSinceLast == 1)
        #expect(lines.first?.sessionsInWindow == 3)
    }

    @Test
    func trainedTodayCountsAsZeroDays() {
        let lines = CoachHistory.lines(for: [makeEntry("Abdomen", daysAgo: [0])], today: today)
        #expect(lines.first?.daysSinceLast == 0)
        #expect(lines.first?.sessionsInWindow == 1)
    }

    @Test
    func sessionsOutsideTheWindowAreIgnored() {
        let lastDayInWindow = CoachHistory.windowDays - 1
        let entry = makeEntry("Espalda", daysAgo: [lastDayInWindow, CoachHistory.windowDays, 40])
        let line = CoachHistory.lines(for: [entry], today: today).first
        #expect(line?.daysSinceLast == lastDayInWindow)
        #expect(line?.sessionsInWindow == 1)
    }

    @Test
    func groupTrainedOnlyBeforeTheWindowReadsAsNotRecent() {
        let entry = makeEntry("Hombros", daysAgo: [CoachHistory.windowDays, 60])
        let line = CoachHistory.lines(for: [entry], today: today).first
        #expect(line?.daysSinceLast == nil)
        #expect(line?.sessionsInWindow == 0)
    }

    @Test
    func indicesFollowTheGivenOrder() {
        // The index is what the model answers with, so it must match the numbered list.
        let entries = [makeEntry("Bíceps"), makeEntry("Tríceps"), makeEntry("Pecho")]
        let lines = CoachHistory.lines(for: entries, today: today)
        #expect(lines.map(\.index) == [0, 1, 2])
        #expect(lines.map(\.name) == ["Bíceps", "Tríceps", "Pecho"])
    }
}
