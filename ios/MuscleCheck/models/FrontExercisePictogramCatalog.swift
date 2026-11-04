//
//  FrontExercisePictogramCatalog.swift
//  MuscleCheck
//
//  The front-view exercises. Hands and feet are the screen-right side; the engine
//  mirrors them. Arm lengths: upper arm 15 + forearm 14 from a shoulder at x 61.
//

import CoreGraphics

private let floorLine = FrontPictogram.floorY

extension FrontPictogram {

    // MARK: - Shoulders

    /// Arms from the sides up to shoulder height, elbows soft.
    static let lateralRaise = FrontPictogram(
        start: .init(hand: .init(x: 64, y: 52.8)),
        end: .init(hand: .init(x: 88, y: 26)),
        props: [.dumbbellsAtHands]
    )

    /// Bent over with soft knees, the torso foreshortened toward the viewer and the head
    /// down between the shoulders: arms hang below the hips, then open into a T.
    static let rearDeltFly = FrontPictogram(
        start: .init(hipY: 56, torsoScale: 0.35, headDrop: 10, hand: .init(x: 63, y: 76),
                     foot: .init(x: 57, y: floorLine - 2)),
        end: .init(hipY: 56, torsoScale: 0.35, headDrop: 10, hand: .init(x: 89, y: 44),
                   foot: .init(x: 57, y: floorLine - 2)),
        props: [.dumbbellsAtHands]
    )

    /// A barbell held at arm's length, the shoulders rising toward the ears.
    static let shrug = FrontPictogram(
        start: .init(hand: .init(x: 62, y: 52.9)),
        end: .init(shrug: 6, hand: .init(x: 62, y: 46.9)),
        props: [.barAtHands]
    )

    /// A barbell from the thighs up to the chest, elbows leading out to shoulder height.
    static let uprightRow = FrontPictogram(
        start: .init(hand: .init(x: 58, y: 52.85)),
        end: .init(hand: .init(x: 64, y: 31)),
        props: [.barAtHands]
    )

    // MARK: - Chest

    /// Standing between two high pulleys, hands sweeping down and together.
    static let cableCrossover = FrontPictogram(
        start: .init(hand: .init(x: 86, y: 20)),
        end: .init(hand: .init(x: 54, y: 52)),
        props: [
            .line(.init(x: 6, y: 6), .init(x: 6, y: floorLine)),
            .line(.init(x: 94, y: 6), .init(x: 94, y: floorLine)),
            .cablesToHands(pulley: .init(x: 94, y: 10)),
        ]
    )

    /// Seen from above, lying on a bench: dumbbells open wide, then meet over the chest.
    static let dumbbellFly = FrontPictogram(
        start: .init(hipY: 60, hand: .init(x: 88, y: 38), foot: .init(x: 57, y: 97.5)),
        end: .init(hipY: 60, hand: .init(x: 53, y: 42), foot: .init(x: 57, y: 97.5)),
        showsFloor: false,
        props: [.box(CGRect(x: 40, y: 12, width: 20, height: 84)), .dumbbellsAlongBody]
    )

    /// Seated, upper arms out to the sides and forearms up against the pads; the pads
    /// close in front of the chest.
    static let pecDeck = FrontPictogram(
        start: .init(hipY: 68, hand: .init(x: 79, y: 24), foot: .init(x: 60, y: floorLine - 2), seated: true),
        end: .init(hipY: 68, hand: .init(x: 56, y: 25), foot: .init(x: 60, y: floorLine - 2), seated: true),
        armBend: 1,
        props: [
            .box(CGRect(x: 41, y: 26, width: 18, height: 44)),
            .box(CGRect(x: 36, y: 66, width: 28, height: 6)),
            .line(.init(x: 50, y: 72), .init(x: 50, y: floorLine)),
            .padsOnForearms,
        ]
    )

    // MARK: - Glutes

    /// Standing on one leg, the other swinging out to the side.
    static let hipAbduction = FrontPictogram(
        start: .init(hand: .init(x: 64, y: 52.8), foot: .init(x: 57, y: floorLine - 2),
                     leftFoot: .init(x: 43, y: floorLine - 2)),
        end: .init(hand: .init(x: 64, y: 52.8), foot: .init(x: 75, y: 87),
                   leftFoot: .init(x: 43, y: floorLine - 2)),
        props: []
    )
}
