//
//  ExerciseRowSnapshotTests.swift
//  MuscleCheckTests
//
//  The AI coach card's exercise rows: a movement we draw gets its pictogram (side or
//  front view), anything else gets the group's icon in grey. Asserted against approved images, like the
//  calendar cell, because "looks right" isn't a property.
//

import Testing
import SnapshotTesting
import SwiftUI
@testable import MuscleCheck

@MainActor
struct ExerciseRowSnapshotTests {

    /// The card's content width on a 393pt-wide iPhone: the screen minus the sheet's and
    /// the block's padding (16pt each side, twice).
    private static let layout = SwiftUISnapshotLayout.fixed(width: 329, height: 3 * 56 + 2 * 8)

    @Test
    func drawnAndUndrawnExercises() {
        let rows = VStack(alignment: .leading, spacing: 8) {
            ExerciseRow(name: "Press de banca", groupIcon: "figure.strengthtraining.traditional")
            ExerciseRow(name: "Elevaciones laterales", groupIcon: "figure.strengthtraining.traditional")
            ExerciseRow(name: "Hack squat", groupIcon: "figure.strengthtraining.traditional")
        }
        .environment(\.animatesExercisePictograms, false)
        .background(Color(.secondarySystemBackground))

        assertSnapshot(of: rows, as: .image(layout: Self.layout, traits: .init(userInterfaceStyle: .light)))
    }
}
