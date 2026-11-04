//
//  ExercisePictogramView.swift
//  MuscleCheck
//
//  Draws an exercise pictogram (side or front view) with Canvas: no image assets, and it follows the tint
//  and dark mode on its own. Animates on a loop; with Reduce Motion (or
//  `animatesExercisePictograms` off, for snapshots) it holds the movement's end pose.
//

import SwiftUI

struct ExercisePictogramView: View {
    let pictogram: PictogramDrawing
    var period: TimeInterval = 3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.animatesExercisePictograms) private var animates

    var body: some View {
        Group {
            if reduceMotion || !animates {
                frame(progress: 1)
            } else {
                TimelineView(.animation) { timeline in
                    frame(progress: ExercisePictogram.progress(
                        time: timeline.date.timeIntervalSinceReferenceDate, period: period))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        // Decorative: the exercise's name is always written next to it.
        .accessibilityHidden(true)
    }

    private func frame(progress: CGFloat) -> some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            context.scaleBy(x: scale, y: scale)
            for shape in pictogram.shapes(at: progress) {
                let path = Path(shape.path)
                let shading = Self.shading(for: shape.layer)
                switch shape.paint {
                case .fill:
                    context.fill(path, with: shading)
                case .stroke(let width):
                    context.stroke(path, with: shading, style: StrokeStyle(lineWidth: width, lineCap: .round))
                }
            }
        }
    }

    private static func shading(for layer: PictogramShape.Layer) -> GraphicsContext.Shading {
        switch layer {
        case .equipmentBack: .style(.tertiary)
        case .equipment: .style(.secondary)
        case .figureFar: .style(.tint.opacity(0.4))
        case .figure: .style(.tint)
        }
    }
}

extension EnvironmentValues {
    /// Off holds every pictogram still, like Reduce Motion: snapshot tests need a frame that
    /// doesn't depend on the clock.
    @Entry var animatesExercisePictograms = true
}

/// One exercise of a coach suggestion: its pictogram when we draw that movement, otherwise
/// the group's own icon in grey, so it never reads as a drawing of the exercise.
struct ExerciseRow: View {
    let name: String
    let groupIcon: String

    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 56

    var body: some View {
        HStack(spacing: 12) {
            tile
                .frame(width: tileSize, height: tileSize)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
            Text(name)
                .font(.appBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var tile: some View {
        if let motion = ExerciseCatalog.motion(for: name) {
            ExercisePictogramView(pictogram: motion.drawing)
                .padding(3)
        } else {
            Image(systemName: groupIcon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
