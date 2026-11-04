//
//  ExercisePictogramCatalog.swift
//  MuscleCheck
//
//  The pose data of every exercise pictogram, by muscle group. Coordinates are a
//  100×100 side view with the floor at y = 94; bones are torso 30, upper arm 15,
//  forearm 14, thigh 19, shin 19, so a straight arm reaches 29 and a straight leg 38.
//  ExercisePictogramTests checks every one for impossible joints. Which name maps to
//  which pictogram is ExerciseMotion's job.
//

import CoreGraphics

// MARK: - Shared scenery

private let floorLine = ExercisePictogram.floorY

/// A flat bench whose top is at y = 70.5, legs at `x1` and `x2`.
private func flatBench(from x0: CGFloat, to x1: CGFloat) -> [PictogramProp] {
    [.beam(.init(x: x0, y: 73), .init(x: x1, y: 73), width: 5),
     .line(.init(x: x0 + 4, y: 75), .init(x: x0 + 4, y: floorLine)),
     .line(.init(x: x1 - 4, y: 75), .init(x: x1 - 4, y: floorLine))]
}

/// A low seat whose top is at `top`, centred on `x`.
private func seat(x: CGFloat, top: CGFloat, halfWidth: CGFloat = 11) -> [PictogramProp] {
    [.beam(.init(x: x - halfWidth, y: top + 2.5), .init(x: x + halfWidth, y: top + 2.5), width: 5),
     .line(.init(x: x, y: top + 5), .init(x: x, y: floorLine))]
}

// MARK: - Chest

extension ExercisePictogram {

    /// Lying on a bench, head to the left; the bar (a plate, end-on) moves chest ↔ lockout.
    static let benchPress = ExercisePictogram(
        start: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                     hand: .init(x: 27, y: 56), foot: .init(x: 76, y: 92)),
        end: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                   hand: .init(x: 25, y: 37.2), foot: .init(x: 76, y: 92)),
        props: [.plateAtHand(radius: 9)] + flatBench(from: 18, to: 62)
    )

    /// Same press on a ~35° incline bench, with dumbbells.
    static let inclineDumbbellPress = ExercisePictogram(
        start: .init(hip: .init(x: 58, y: 70), torsoAngle: -145,
                     hand: .init(x: 37, y: 47), foot: .init(x: 82, y: 92)),
        end: .init(hip: .init(x: 58, y: 70), torsoAngle: -145,
                   hand: .init(x: 34, y: 23.9), foot: .init(x: 82, y: 92)),
        props: [
            .dumbbellAtHand,
            .beam(.init(x: 55, y: 77), .init(x: 30, y: 59.5), width: 5),
            .beam(.init(x: 54, y: 77), .init(x: 70, y: 77), width: 5),
            .line(.init(x: 60, y: 79), .init(x: 60, y: floorLine)),
            .line(.init(x: 36, y: 64), .init(x: 36, y: floorLine)),
        ]
    )

    /// Plank facing right, pivoting on the balls of the feet. Ankle → hip → shoulder
    /// stay one straight line (legs exactly at full reach). Plank angle 21.3° at the
    /// top and 9° at the bottom, where the forearm stands vertical over the hand.
    static let pushUp = ExercisePictogram(
        start: .init(hip: .init(x: 49.4, y: 75.2), torsoAngle: -21.3,
                     hand: .init(x: 67, y: 91.2), foot: .init(x: 14, y: 89)),
        end: .init(hip: .init(x: 51.53, y: 83.06), torsoAngle: -9,
                   hand: .init(x: 67, y: 91.2), foot: .init(x: 14, y: 89)),
        props: []
    )

    /// Head-down bench, feet hooked under a roller; the bar travels vertically.
    static let declineBenchPress = ExercisePictogram(
        start: .init(hip: .init(x: 58, y: 60), torsoAngle: 160,
                     hand: .init(x: 32.8, y: 61.3), foot: .init(x: 80, y: 68)),
        end: .init(hip: .init(x: 58, y: 60), torsoAngle: 160,
                   hand: .init(x: 30.8, y: 41.4), foot: .init(x: 80, y: 68)),
        props: [
            .plateAtHand(radius: 9),
            .beam(.init(x: 62, y: 65), .init(x: 22, y: 79.5), width: 5),
            .line(.init(x: 56, y: 67), .init(x: 56, y: floorLine)),
            .line(.init(x: 30, y: 78), .init(x: 30, y: floorLine)),
            .beam(.init(x: 79, y: 63.5), .init(x: 81, y: 63.5), width: 6),
            .line(.init(x: 84, y: 63.5), .init(x: 84, y: floorLine)),
        ]
    )

    /// Dip with the torso leaning well forward, which shifts the work to the chest.
    static let chestDip = ExercisePictogram(
        start: .init(hip: .init(x: 40.5, y: 46), torsoAngle: -60,
                     hand: .init(x: 55, y: 48), foot: .init(x: 28, y: 66)),
        end: .init(hip: .init(x: 45, y: 61), torsoAngle: -60,
                   hand: .init(x: 55, y: 48), foot: .init(x: 32, y: 80)),
        props: [
            .beam(.init(x: 47, y: 50.5), .init(x: 63, y: 50.5), width: 4),
            .line(.init(x: 61, y: 51), .init(x: 61, y: floorLine)),
        ]
    )
}

// MARK: - Back

extension ExercisePictogram {

    /// Hanging from a bar, chin over it at the top. Zoomed out so the head fits.
    static let pullUp = ExercisePictogram(
        start: .init(hip: .init(x: 50, y: 67), torsoAngle: -88,
                     hand: .init(x: 50, y: 8), foot: .init(x: 40, y: 86)),
        end: .init(hip: .init(x: 49, y: 44), torsoAngle: -88,
                   hand: .init(x: 50, y: 8), foot: .init(x: 39, y: 63)),
        viewScale: 0.85,
        props: [
            .beam(.init(x: 28, y: 8), .init(x: 72, y: 8), width: 3),
            .line(.init(x: 28, y: 8), .init(x: 28, y: floorLine)),
            .line(.init(x: 72, y: 8), .init(x: 72, y: floorLine)),
        ]
    )

    /// Seated, thighs under a pad, pulling the bar from overhead to the upper chest.
    static let latPulldown = ExercisePictogram(
        start: .init(hip: .init(x: 42, y: 68), torsoAngle: -100,
                     hand: .init(x: 40, y: 9.7), foot: .init(x: 62, y: 92)),
        end: .init(hip: .init(x: 42, y: 68), torsoAngle: -100,
                   hand: .init(x: 42, y: 33), foot: .init(x: 62, y: 92)),
        props: [
            .beam(.init(x: 26, y: 3), .init(x: 26, y: floorLine), width: 5),
            .beam(.init(x: 26, y: 3), .init(x: 52, y: 3), width: 4),
            .cableToHand(pulley: .init(x: 40, y: 4)),
            .beam(.init(x: 55, y: 66), .init(x: 57, y: 66), width: 6),
        ] + seat(x: 42, top: 72.5)
    )

    /// Hip hinged ~65°, knees soft; the bar comes from hanging to the lower chest.
    static let barbellRow = ExercisePictogram(
        start: .init(hip: .init(x: 38, y: 58), torsoAngle: -25,
                     hand: .init(x: 65.5, y: 74.2), foot: .init(x: 46, y: floorLine - 2)),
        end: .init(hip: .init(x: 38, y: 58), torsoAngle: -25,
                   hand: .init(x: 56, y: 56), foot: .init(x: 46, y: floorLine - 2)),
        props: [.plateAtHand(radius: 8)]
    )

    /// Far knee and hand on the bench, near foot on the floor, near hand rowing.
    static let oneArmDumbbellRow = ExercisePictogram(
        start: .init(hip: .init(x: 36, y: 61), torsoAngle: -18.4,
                     hand: .init(x: 65, y: 80.3), foot: .init(x: 44, y: floorLine - 2),
                     farHand: .init(x: 66, y: 77.5), farFoot: .init(x: 18, y: 77.5)),
        end: .init(hip: .init(x: 36, y: 61), torsoAngle: -18.4,
                   hand: .init(x: 52, y: 60), foot: .init(x: 44, y: floorLine - 2),
                   farHand: .init(x: 66, y: 77.5), farFoot: .init(x: 18, y: 77.5)),
        props: [
            .dumbbellAtHand,
            .beam(.init(x: 14, y: 82.5), .init(x: 74, y: 82.5), width: 5),
            .line(.init(x: 20, y: 85), .init(x: 20, y: floorLine)),
            .line(.init(x: 68, y: 85), .init(x: 68, y: floorLine)),
        ]
    )

    /// Seated on the floor bench, feet on the plate; leaning in, then rowing upright.
    static let seatedCableRow = ExercisePictogram(
        start: .init(hip: .init(x: 30, y: 76), torsoAngle: -75,
                     hand: .init(x: 64, y: 52), foot: .init(x: 66, y: 78)),
        end: .init(hip: .init(x: 30, y: 76), torsoAngle: -95,
                   hand: .init(x: 37, y: 58), foot: .init(x: 66, y: 78)),
        props: [
            .beam(.init(x: 88, y: 30), .init(x: 88, y: floorLine), width: 6),
            .cableToHand(pulley: .init(x: 84, y: 60)),
            .beam(.init(x: 71, y: 70), .init(x: 71, y: 86), width: 3),
        ] + seat(x: 28, top: 80.5, halfWidth: 12)
    )

    /// From the floor to standing tall: hips and shoulders rise together.
    static let deadlift = ExercisePictogram(
        start: .init(hip: .init(x: 36, y: 70), torsoAngle: -25.7,
                     hand: .init(x: 60, y: 84), foot: .init(x: 52, y: floorLine - 2)),
        end: .init(hip: .init(x: 46, y: 54.5), torsoAngle: -90,
                   hand: .init(x: 47, y: 53), foot: .init(x: 52, y: floorLine - 2)),
        props: [.plateAtHand(radius: 9)]
    )

    /// Lying across the bench; a dumbbell goes from over the chest to behind the head.
    static let pullover = ExercisePictogram(
        start: .init(hip: .init(x: 66, y: 66), torsoAngle: 180,
                     hand: .init(x: 37, y: 37.2), foot: .init(x: 88, y: 92)),
        end: .init(hip: .init(x: 66, y: 66), torsoAngle: 180,
                   hand: .init(x: 10, y: 72), foot: .init(x: 88, y: 92)),
        props: [.dumbbellAtHand] + flatBench(from: 30, to: 74)
    )
}

// MARK: - Legs

extension ExercisePictogram {

    /// Bar on the upper back; hips back and down, knees forward, chest up.
    static let squat = ExercisePictogram(
        start: .init(hip: .init(x: 48, y: 54), torsoAngle: -88,
                     hand: .init(x: 52.05, y: 28.02), foot: .init(x: 50, y: floorLine - 2)),
        end: .init(hip: .init(x: 34, y: 74), torsoAngle: -55,
                   hand: .init(x: 54.21, y: 53.43), foot: .init(x: 50, y: floorLine - 2)),
        props: [.plateAtShoulder(radius: 9)]
    )

    /// Reclined at 45°, pushing the sled up and away along the rails.
    static let legPress = ExercisePictogram(
        start: .init(hip: .init(x: 40, y: 76), torsoAngle: -135,
                     hand: .init(x: 36, y: 74), foot: .init(x: 58.4, y: 57.6), footAngle: -135),
        end: .init(hip: .init(x: 40, y: 76), torsoAngle: -135,
                   hand: .init(x: 36, y: 74), foot: .init(x: 66.1, y: 49.9), footAngle: -135),
        props: [
            .sledOnRail(from: .init(x: 60, y: 65.6), to: .init(x: 90, y: 35.6)),
            .line(.init(x: 62, y: 64), .init(x: 62, y: floorLine)),
            .beam(.init(x: 36.1, y: 79.9), .init(x: 14.9, y: 58.7), width: 5),
            .beam(.init(x: 34, y: 82), .init(x: 50, y: 82), width: 5),
            .line(.init(x: 40, y: 84), .init(x: 40, y: floorLine)),
            .line(.init(x: 18, y: 62), .init(x: 18, y: floorLine)),
        ]
    )

    /// Knees soft and fixed; the hips push back and the bar slides down the legs.
    static let romanianDeadlift = ExercisePictogram(
        start: .init(hip: .init(x: 46, y: 54), torsoAngle: -90,
                     hand: .init(x: 47, y: 53), foot: .init(x: 48, y: floorLine - 2)),
        end: .init(hip: .init(x: 36, y: 58), torsoAngle: -35,
                   hand: .init(x: 58, y: 69.6), foot: .init(x: 48, y: floorLine - 2)),
        props: [.plateAtHand(radius: 8)]
    )

    /// Split stance; the back knee drops to just above the floor.
    static let lunge = ExercisePictogram(
        start: .init(hip: .init(x: 45, y: 61), torsoAngle: -90,
                     hand: .init(x: 46, y: 59.8), foot: .init(x: 66, y: floorLine - 2),
                     farFoot: .init(x: 26, y: 89)),
        end: .init(hip: .init(x: 44, y: 74), torsoAngle: -90,
                   hand: .init(x: 45, y: 72.9), foot: .init(x: 66, y: floorLine - 2),
                   farFoot: .init(x: 26, y: 89)),
        props: []
    )

    /// Seated, knee at the seat's edge; the shin swings from hanging to straight.
    static let legExtension = ExercisePictogram(
        start: .init(hip: .init(x: 40, y: 66), torsoAngle: -95,
                     hand: .init(x: 42, y: 64), foot: .init(x: 59, y: 85)),
        mid: .init(hip: .init(x: 40, y: 66), torsoAngle: -95,
                   hand: .init(x: 42, y: 64), foot: .init(x: 72.4, y: 79.4)),
        end: .init(hip: .init(x: 40, y: 66), torsoAngle: -95,
                   hand: .init(x: 42, y: 64), foot: .init(x: 77.9, y: 66)),
        props: [
            .padAtFoot(radius: 3.5),
            .beam(.init(x: 28, y: 73), .init(x: 60, y: 73), width: 5),
            .beam(.init(x: 34.5, y: 70), .init(x: 31.5, y: 38), width: 5),
            .line(.init(x: 30, y: 75), .init(x: 30, y: floorLine)),
        ]
    )

    /// Face down on the bench; heels curl up toward the glutes.
    static let legCurl = ExercisePictogram(
        start: .init(hip: .init(x: 46, y: 64), torsoAngle: 0,
                     hand: .init(x: 88, y: 70), foot: .init(x: 8.1, y: 64)),
        end: .init(hip: .init(x: 46, y: 64), torsoAngle: 0,
                   hand: .init(x: 88, y: 70), foot: .init(x: 34, y: 48)),
        props: [
            .padAtFoot(radius: 3.5),
            .beam(.init(x: 16, y: 71), .init(x: 84, y: 71), width: 5),
            .line(.init(x: 22, y: 73), .init(x: 22, y: floorLine)),
            .line(.init(x: 78, y: 73), .init(x: 78, y: floorLine)),
        ]
    )

    /// On a step with the heels hanging off: they drop below the edge, then rise high
    /// onto the balls of the feet. A hand on a post for balance.
    static let calfRaise = ExercisePictogram(
        start: .init(hip: .init(x: 48.37, y: 43.45), torsoAngle: -90,
                     hand: .init(x: 68.5, y: 33.45), foot: .init(x: 48.37, y: 81.25), footAngle: -30),
        end: .init(hip: .init(x: 50.75, y: 34.57), torsoAngle: -90,
                   hand: .init(x: 68.5, y: 24.57), foot: .init(x: 50.75, y: 72.37), footAngle: 60),
        viewScale: 0.85,
        footLength: 6.5,
        props: [
            .box(CGRect(x: 53, y: 80, width: 14, height: floorLine - 80)),
            .line(.init(x: 70, y: floorLine), .init(x: 70, y: 14)),
        ]
    )
}

// MARK: - Shoulders

extension ExercisePictogram {

    /// Standing; the bar goes from the collarbone to overhead. Zoomed out to fit.
    static let militaryPress = ExercisePictogram(
        start: .init(hip: .init(x: 48, y: 54), torsoAngle: -90,
                     hand: .init(x: 52, y: 26), foot: .init(x: 49, y: floorLine - 2)),
        end: .init(hip: .init(x: 48, y: 54), torsoAngle: -90,
                   hand: .init(x: 49, y: -4.9), foot: .init(x: 49, y: floorLine - 2)),
        viewScale: 0.85,
        props: [.plateAtHand(radius: 9)]
    )

    /// Seated against a back pad, dumbbells from shoulder height to overhead.
    static let seatedDumbbellPress = ExercisePictogram(
        start: .init(hip: .init(x: 44, y: 70), torsoAngle: -90,
                     hand: .init(x: 47, y: 38), foot: .init(x: 64, y: 92)),
        end: .init(hip: .init(x: 44, y: 70), torsoAngle: -90,
                   hand: .init(x: 44.5, y: 11.1), foot: .init(x: 64, y: 92)),
        props: [
            .dumbbellAtHand,
            .beam(.init(x: 38.5, y: 72), .init(x: 38.5, y: 44), width: 5),
        ] + seat(x: 45, top: 74.5)
    )

    /// Straight arm from the front of the thigh up to shoulder height. The start hand sits
    /// a little forward so the arm doesn't merge with the torso.
    static let frontRaise = ExercisePictogram(
        start: .init(hip: .init(x: 48, y: 54), torsoAngle: -90,
                     hand: .init(x: 57, y: 51.5), foot: .init(x: 49, y: floorLine - 2)),
        end: .init(hip: .init(x: 48, y: 54), torsoAngle: -90,
                   hand: .init(x: 76.9, y: 25), foot: .init(x: 49, y: floorLine - 2)),
        props: [.dumbbellAtHand]
    )

    /// Hips high in an inverted V; the head lowers toward the floor between the hands.
    static let pikePushUp = ExercisePictogram(
        start: .init(hip: .init(x: 33, y: 56.1), torsoAngle: 11,
                     hand: .init(x: 61, y: 90.5), foot: .init(x: 14, y: 89)),
        end: .init(hip: .init(x: 33, y: 56.1), torsoAngle: 45,
                   hand: .init(x: 61, y: 90.5), foot: .init(x: 14, y: 89)),
        props: []
    )

    /// One end of a barbell anchored on the floor; the free end is pressed up and out.
    static let landminePress = ExercisePictogram(
        start: .init(hip: .init(x: 40, y: 54), torsoAngle: -80,
                     hand: .init(x: 50, y: 27), foot: .init(x: 41, y: floorLine - 2)),
        end: .init(hip: .init(x: 40, y: 54), torsoAngle: -80,
                   hand: .init(x: 63.8, y: 2.4), foot: .init(x: 41, y: floorLine - 2)),
        viewScale: 0.85,
        props: [.barToHand(pivot: .init(x: 98, y: 92))]
    )
}

// MARK: - Biceps

/// A standing curl: the elbow stays pinned at the side while the forearm sweeps up.
/// `x` is the hip; the mid pose has the forearm level, which keeps the arc round.
private func standingCurl(hipX x: CGFloat, props: [PictogramProp]) -> ExercisePictogram {
    let hip = CGPoint(x: x, y: 54), foot = CGPoint(x: x + 1, y: floorLine - 2)
    func pose(_ hand: CGPoint) -> PictogramPose {
        .init(hip: hip, torsoAngle: -90, hand: hand, foot: foot)
    }
    return ExercisePictogram(
        start: pose(.init(x: x + 1, y: 52.9)),
        mid: pose(.init(x: x + 14.5, y: 39)),
        end: pose(.init(x: x + 6.1, y: 26.2)),
        props: props
    )
}

extension ExercisePictogram {

    static let barbellCurl = standingCurl(hipX: 46, props: [.plateAtHand(radius: 8)])
    static let dumbbellCurl = standingCurl(hipX: 46, props: [.dumbbellAtHand])
    static let hammerCurl = standingCurl(hipX: 46, props: [.hammerDumbbellAtHand])
    static let cableCurl = standingCurl(hipX: 40, props: [
        .beam(.init(x: 88, y: 40), .init(x: 88, y: floorLine), width: 6),
        .cableToHand(pulley: .init(x: 84, y: 90)),
    ])

    /// Upper arm resting on the angled pad; the forearm curls from extended to up.
    static let preacherCurl: ExercisePictogram = {
        func pose(_ hand: CGPoint) -> PictogramPose {
            .init(hip: .init(x: 40, y: 68), torsoAngle: -80, hand: hand, foot: .init(x: 60, y: 92))
        }
        return ExercisePictogram(
            start: pose(.init(x: 62.84, y: 61.29)),
            mid: pose(.init(x: 67.94, y: 46.95)),
            end: pose(.init(x: 51.56, y: 36.59)),
            props: [
                .dumbbellAtHand,
                .beam(.init(x: 43.5, y: 43.6), .init(x: 53.9, y: 57), width: 5),
                .line(.init(x: 52, y: 57), .init(x: 52, y: floorLine)),
            ] + seat(x: 40, top: 72.5, halfWidth: 10)
        )
    }()

    /// Seated, leaning in, the elbow braced against the inner thigh.
    static let concentrationCurl: ExercisePictogram = {
        func pose(_ hand: CGPoint) -> PictogramPose {
            .init(hip: .init(x: 36, y: 70), torsoAngle: -45, hand: hand, foot: .init(x: 62, y: 92))
        }
        return ExercisePictogram(
            start: pose(.init(x: 58.5, y: 77.7)),
            mid: pose(.init(x: 71.5, y: 63.8)),
            end: pose(.init(x: 62, y: 52)),
            props: [.dumbbellAtHand] + seat(x: 34, top: 74.5, halfWidth: 12)
        )
    }()

    /// Lying back on a steep incline; arms hang straight, then curl.
    static let inclineCurl: ExercisePictogram = {
        func pose(_ hand: CGPoint) -> PictogramPose {
            .init(hip: .init(x: 58, y: 70), torsoAngle: -135, hand: hand, foot: .init(x: 82, y: 92))
        }
        return ExercisePictogram(
            start: pose(.init(x: 37.5, y: 77.7)),
            mid: pose(.init(x: 51.3, y: 63.8)),
            end: pose(.init(x: 42.9, y: 51)),
            props: [
                .dumbbellAtHand,
                .beam(.init(x: 54.1, y: 73.9), .init(x: 32.9, y: 52.7), width: 5),
                .beam(.init(x: 54, y: 77), .init(x: 70, y: 77), width: 5),
                .line(.init(x: 62, y: 79), .init(x: 62, y: floorLine)),
                .line(.init(x: 46, y: 66), .init(x: 46, y: floorLine)),
            ]
        )
    }()
}

// MARK: - Triceps

extension ExercisePictogram {

    /// Standing, facing a cable tower on the right; elbows pinned, forearms push down.
    static let cablePushdown = ExercisePictogram(
        start: .init(hip: .init(x: 44, y: 54), torsoAngle: -80,
                     hand: .init(x: 63, y: 34), foot: .init(x: 44, y: floorLine - 2)),
        end: .init(hip: .init(x: 44, y: 54), torsoAngle: -80,
                   hand: .init(x: 52, y: 53), foot: .init(x: 44, y: floorLine - 2)),
        props: [
            .beam(.init(x: 88, y: 8), .init(x: 88, y: floorLine), width: 7),
            .cableToHand(pulley: .init(x: 84, y: 12)),
        ]
    )

    /// Between parallel bars, hands fixed; the body lowers with a slight forward lean.
    static let tricepsDip = ExercisePictogram(
        start: .init(hip: .init(x: 49.4, y: 49), torsoAngle: -85,
                     hand: .init(x: 55, y: 48), foot: .init(x: 38, y: 76)),
        end: .init(hip: .init(x: 52.4, y: 64), torsoAngle: -85,
                   hand: .init(x: 55, y: 48), foot: .init(x: 41, y: 86)),
        props: [
            .beam(.init(x: 44, y: 50), .init(x: 60, y: 50), width: 4),
            .line(.init(x: 58, y: 50), .init(x: 58, y: floorLine)),
        ]
    )

    /// Lying on a bench; upper arms stay put, the bar travels to the forehead and back.
    static let skullCrusher = ExercisePictogram(
        start: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                     hand: .init(x: 22.5, y: 37.1), foot: .init(x: 76, y: 92)),
        end: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                   hand: .init(x: 10, y: 55), foot: .init(x: 76, y: 92)),
        props: [.plateAtHand(radius: 7)] + flatBench(from: 18, to: 62)
    )

    /// Seated; the dumbbell drops behind the head and presses back up.
    static let overheadTricepsExtension = ExercisePictogram(
        start: .init(hip: .init(x: 44, y: 70), torsoAngle: -90,
                     hand: .init(x: 33, y: 31), foot: .init(x: 64, y: 92)),
        end: .init(hip: .init(x: 44, y: 70), torsoAngle: -90,
                   hand: .init(x: 45.5, y: 11.1), foot: .init(x: 64, y: 92)),
        props: [.dumbbellAtHand] + seat(x: 45, top: 74.5)
    )

    /// Bench press with the bar lower on the chest and elbows tucked.
    static let closeGripBenchPress = ExercisePictogram(
        start: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                     hand: .init(x: 31, y: 58), foot: .init(x: 76, y: 92)),
        end: .init(hip: .init(x: 54, y: 66), torsoAngle: 180,
                   hand: .init(x: 26, y: 37.2), foot: .init(x: 76, y: 92)),
        props: [.plateAtHand(radius: 8)] + flatBench(from: 18, to: 62)
    )

    /// Bent over, upper arm level and still; the forearm kicks back to straight.
    static let tricepsKickback = ExercisePictogram(
        start: .init(hip: .init(x: 40, y: 56), torsoAngle: -35,
                     hand: .init(x: 50.02, y: 56.43), foot: .init(x: 44, y: floorLine - 2)),
        end: .init(hip: .init(x: 40, y: 56), torsoAngle: -35,
                   hand: .init(x: 36.54, y: 45.81), foot: .init(x: 44, y: floorLine - 2)),
        props: [.dumbbellAtHand]
    )

    /// Hands on a bench behind, heels on the floor; the hips dip and rise.
    static let benchDip = ExercisePictogram(
        start: .init(hip: .init(x: 35.6, y: 70), torsoAngle: -95,
                     hand: .init(x: 32, y: 68), foot: .init(x: 62, y: floorLine - 2)),
        end: .init(hip: .init(x: 36.6, y: 81.9), torsoAngle: -95,
                   hand: .init(x: 32, y: 68), foot: .init(x: 62, y: floorLine - 2)),
        props: [
            .beam(.init(x: 12, y: 73), .init(x: 34, y: 73), width: 5),
            .line(.init(x: 16, y: 75), .init(x: 16, y: floorLine)),
            .line(.init(x: 30, y: 75), .init(x: 30, y: floorLine)),
        ]
    )
}

// MARK: - Abdomen

extension ExercisePictogram {

    /// On the floor, knees bent; the shoulders curl up, hands behind the head.
    static let crunch = ExercisePictogram(
        start: .init(hip: .init(x: 54, y: 87.5), torsoAngle: 180,
                     hand: .init(x: 16, y: 81), foot: .init(x: 76, y: floorLine - 2)),
        end: .init(hip: .init(x: 54, y: 87.5), torsoAngle: 210,
                   hand: .init(x: 21, y: 61), foot: .init(x: 76, y: floorLine - 2)),
        props: []
    )

    /// Forearm plank: elbows under the shoulders, one straight line; a slow breath.
    static let plank = ExercisePictogram(
        start: .init(hip: .init(x: 45.35, y: 82), torsoAngle: -10.6,
                     hand: .init(x: 88.8, y: 91.5), foot: .init(x: 8, y: 89)),
        end: .init(hip: .init(x: 45.24, y: 81.43), torsoAngle: -11.5,
                   hand: .init(x: 88.8, y: 91.5), foot: .init(x: 8, y: 89)),
        props: []
    )

    /// Hanging from a bar, straight legs swing up to level. Zoomed out to fit.
    static let hangingLegRaise = ExercisePictogram(
        start: .init(hip: .init(x: 50, y: 52), torsoAngle: -90,
                     hand: .init(x: 50, y: -7), foot: .init(x: 50, y: 90)),
        end: .init(hip: .init(x: 49, y: 52), torsoAngle: -95,
                   hand: .init(x: 50, y: -7), foot: .init(x: 87, y: 52)),
        viewScale: 0.8,
        props: [
            .beam(.init(x: 28, y: -7), .init(x: 72, y: -7), width: 3),
            .line(.init(x: 28, y: -7), .init(x: 28, y: floorLine)),
            .line(.init(x: 72, y: -7), .init(x: 72, y: floorLine)),
        ]
    )

    /// Kneeling; the wheel rolls out until the body is nearly flat. Zoomed out to fit.
    static let abWheel = ExercisePictogram(
        start: .init(hip: .init(x: 34, y: 72.9), torsoAngle: -23.1,
                     hand: .init(x: 61.6, y: 88), foot: .init(x: 11, y: 91.5), footAngle: 180),
        end: .init(hip: .init(x: 45.2, y: 80.1), torsoAngle: -8,
                   hand: .init(x: 100, y: 88), foot: .init(x: 11, y: 91.5), footAngle: 180),
        viewScale: 0.8,
        props: [.wheelAtHand(radius: 4)]
    )
}
