//
//  SharedMuscleEntryTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 22/10/2025.
//

import XCTest
@testable import MuscleCheck

final class SharedMuscleEntryTests: XCTestCase {

    func testInit() {
        let entry = SharedMuscleEntry(name: "Pecho", isChecked: true)
        XCTAssertEqual(entry.name, "Pecho")
        XCTAssertTrue(entry.isChecked)
    }

    func testCodable() throws {
        let entry = SharedMuscleEntry(name: "Espalda", isChecked: false)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SharedMuscleEntry.self, from: data)
        XCTAssertEqual(entry, decoded)
    }

    func testHashable() {
        let entry1 = SharedMuscleEntry(name: "Piernas", isChecked: false)
        let entry2 = SharedMuscleEntry(name: "Piernas", isChecked: false)
        let set: Set = [entry1, entry2]
        XCTAssertEqual(set.count, 1)
    }
}
