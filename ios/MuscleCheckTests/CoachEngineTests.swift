//
//  CoachEngineTests.swift
//  MuscleCheckTests
//

import Testing
@testable import MuscleCheck

struct CoachEngineTests {

    @Test
    func analyticsValuesAreStable() {
        // Sent as the `engine` analytics parameter: renaming them breaks dashboards.
        #expect(CoachEngine.privateCloud.rawValue == "pcc")
        #expect(CoachEngine.onDevice.rawValue == "on_device")
    }
}
