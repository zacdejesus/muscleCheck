//
//  MuscleEntryWeightFormatTests.swift
//  MuscleCheckTests
//
//  Covers `formattedLastWeight`, which displays weights as whole numbers (no decimals).
//  Serialized because it reads the shared `weightUnit` preference.
//

import Testing
@testable import MuscleCheck
import Foundation

@Suite(.serialized)
struct MuscleEntryWeightFormatTests {

    private func entry(weightKg: Double?) -> MuscleEntry {
        let e = MuscleEntry(name: "Pecho")
        if let w = weightKg { e.addSession(Date(), weight: w) }
        return e
    }

    @Test
    func testWholeNumberKg() {
        UserDefaultsManager.shared.weightUnit = .kg
        #expect(entry(weightKg: 60).formattedLastWeight == "60 kg")
    }

    @Test
    func testRoundsDownKg() {
        UserDefaultsManager.shared.weightUnit = .kg
        #expect(entry(weightKg: 72.4).formattedLastWeight == "72 kg")
    }

    @Test
    func testRoundsUpKg() {
        UserDefaultsManager.shared.weightUnit = .kg
        #expect(entry(weightKg: 72.6).formattedLastWeight == "73 kg")
    }

    @Test
    func testConvertsAndRoundsLbs() {
        UserDefaultsManager.shared.weightUnit = .lbs
        // 20 kg → 44.09 lbs → "44 lbs"
        #expect(entry(weightKg: 20).formattedLastWeight == "44 lbs")
    }

    @Test
    func testNilWhenNoWeight() {
        UserDefaultsManager.shared.weightUnit = .kg
        #expect(entry(weightKg: nil).formattedLastWeight == nil)
    }
}
