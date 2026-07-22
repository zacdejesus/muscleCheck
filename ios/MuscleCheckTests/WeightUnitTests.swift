//
//  WeightUnitTests.swift
//  MuscleCheckTests
//

import Testing
@testable import MuscleCheck
import Foundation

struct WeightUnitTests {

    // MARK: - displayValue(fromKg:)

    @Test
    func testKgDisplayIsIdentity() {
        #expect(WeightUnit.kg.displayValue(fromKg: 80.0) == 80.0)
        #expect(WeightUnit.kg.displayValue(fromKg: 0) == 0)
    }

    @Test
    func testLbsDisplayMultipliesByConversionFactor() {
        let kg = 100.0
        let lbs = WeightUnit.lbs.displayValue(fromKg: kg)
        // 100 kg ≈ 220.462 lbs
        #expect(abs(lbs - 220.462) < 0.001)
    }

    // MARK: - toKg

    @Test
    func testToKgFromKgIsIdentity() {
        #expect(WeightUnit.kg.toKg(80.0) == 80.0)
    }

    @Test
    func testToKgFromLbsDividesByConversionFactor() {
        let lbs = 220.462
        let kg = WeightUnit.lbs.toKg(lbs)
        #expect(abs(kg - 100.0) < 0.001)
    }

    // MARK: - round-trip

    @Test
    func testRoundTripKgPreservesValue() {
        for value in [0.5, 1.0, 60.0, 80.5, 100.0, 250.0] {
            let lbs = WeightUnit.lbs.displayValue(fromKg: value)
            let backToKg = WeightUnit.lbs.toKg(lbs)
            #expect(abs(backToKg - value) < 0.0001, "Round-trip failed for \(value)")
        }
    }

    // MARK: - display label

    @Test
    func testDisplayLabel() {
        #expect(WeightUnit.kg.displayLabel == "kg")
        #expect(WeightUnit.lbs.displayLabel == "lbs")
    }

    // MARK: - rawValue / Codable

    @Test
    func testRawValueRoundTrip() {
        #expect(WeightUnit(rawValue: "kg") == .kg)
        #expect(WeightUnit(rawValue: "lbs") == .lbs)
        #expect(WeightUnit(rawValue: "invalid") == nil)
    }

    @Test
    func testAllCasesIsTwo() {
        #expect(WeightUnit.allCases.count == 2)
    }
}
