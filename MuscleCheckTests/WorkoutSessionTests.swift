//
//  WorkoutSessionTests.swift
//  MuscleCheckTests
//
//  Guards backward compatibility: sessions persisted before sets/reps existed
//  (only id/date/weight) must still decode, with the new fields defaulting to nil.
//

import Testing
@testable import MuscleCheck
import Foundation

struct WorkoutSessionTests {

    @Test
    func testDecodesLegacyJSONWithoutSetsAndReps() throws {
        // Shape of a WorkoutSession encoded before sets/reps were added.
        let json = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "date": 738000000,
            "weight": 80
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let session = try decoder.decode(WorkoutSession.self, from: json)

        #expect(session.weight == 80)
        #expect(session.sets == nil)
        #expect(session.reps == nil)
    }

    @Test
    func testDecodesLegacyJSONWithoutWeightEither() throws {
        let json = """
        {
            "id": "22222222-2222-2222-2222-222222222222",
            "date": 738000000
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder().decode(WorkoutSession.self, from: json)

        #expect(session.weight == nil)
        #expect(session.sets == nil)
        #expect(session.reps == nil)
    }

    @Test
    func testRoundTripPreservesAllFields() throws {
        let original = WorkoutSession(weight: 90, sets: 5, reps: 8, date: Date())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutSession.self, from: data)

        #expect(decoded.weight == 90)
        #expect(decoded.sets == 5)
        #expect(decoded.reps == 8)
        #expect(decoded.id == original.id)
    }
}
