//
//  CloudCoachPromptTests.swift
//  MuscleCheckTests
//
//  The history lines are what the Private Cloud Compute model reads to choose and
//  explain; their shape is the one tuned on device. Asserted in English, the
//  language the test host runs in.
//

import Testing
@testable import MuscleCheck

struct CloudCoachPromptTests {

    private var isEnglish: Bool { (LocalizedStrings.appLanguage ?? "en") == "en" }

    @Test
    func listsEachGroupWithItsHistory() {
        guard isEnglish else { return }
        let prompt = LocalizedStrings.cloudCoachPrompt(history: [
            .init(index: 0, name: "Back", daysSinceLast: 4, sessionsInWindow: 2),
            .init(index: 1, name: "Legs", daysSinceLast: 1, sessionsInWindow: 3),
            .init(index: 2, name: "Abs", daysSinceLast: 0, sessionsInWindow: 1),
            .init(index: 3, name: "Calves", daysSinceLast: nil, sessionsInWindow: 0)
        ])
        #expect(prompt.contains("""
        0=Back: 4 days ago; 2
        1=Legs: yesterday; 3
        2=Abs: today; 1
        3=Calves: not in the last 4 weeks; 0
        """))
    }

    @Test
    func asksForTheDayInTheAppLanguage() {
        guard isEnglish else { return }
        let prompt = LocalizedStrings.cloudCoachPrompt(history: [])
        #expect(prompt.contains("Write EVERYTHING in English"))
    }
}
