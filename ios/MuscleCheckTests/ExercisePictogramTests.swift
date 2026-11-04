//
//  ExercisePictogramTests.swift
//  MuscleCheckTests
//
//  Anatomy checks for every code-drawn exercise pictogram, sampled across the whole
//  movement. Eyeballing frames misses things (a push-up once had its knees folding
//  backwards), so the rules a human body can't break are asserted here.
//
//  Convention: with `facing == 1` the chest faces "clockwise" from the torso
//  direction in screen space (y down). A knee then always folds with a positive
//  cross(thigh, shin) and an elbow with a negative cross(upperArm, forearm);
//  `facing == -1` mirrors both signs.
//

import Testing
@testable import MuscleCheck
import CoreGraphics

struct ExercisePictogramTests {

    /// sin of ~1.7°: straight limbs land within this of zero from float noise.
    private static let straightTolerance: CGFloat = 0.03
    private static let samples = stride(from: 0.0, through: 1.0, by: 0.05).map { CGFloat($0) }
    private static let ids = ExerciseMotion.allCases

    private static func pictogram(_ motion: ExerciseMotion) -> ExercisePictogram {
        motion.pictogram
    }

    /// Normalized cross product of the two segments meeting at `joint`:
    /// sin of the bend angle, signed by the side it bends to.
    private static func bend(_ a: CGPoint, _ joint: CGPoint, _ b: CGPoint) -> CGFloat {
        let u = CGPoint(x: joint.x - a.x, y: joint.y - a.y)
        let v = CGPoint(x: b.x - joint.x, y: b.y - joint.y)
        return (u.x * v.y - u.y * v.x) / (hypot(u.x, u.y) * hypot(v.x, v.y))
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    // MARK: - Joints

    @Test("Knees never fold backwards", arguments: ids)
    func kneesFoldForward(id: ExerciseMotion) {
        let pictogram = Self.pictogram(id)
        for p in Self.samples {
            let s = pictogram.skeleton(at: p)
            for (side, hip, knee, ankle) in [("near", s.hip, s.knee, s.ankle),
                                             ("far", s.farHip, s.farKnee, s.farAnkle)] {
                let bend = Self.bend(hip, knee, ankle) * pictogram.facing
                #expect(bend >= -Self.straightTolerance, "\(id) \(side) knee at \(p): \(bend)")
            }
        }
    }

    @Test("Elbows never hyperextend", arguments: ids)
    func elbowsFoldForward(id: ExerciseMotion) {
        let pictogram = Self.pictogram(id)
        for p in Self.samples {
            let s = pictogram.skeleton(at: p)
            for (side, shoulder, elbow, hand) in [("near", s.shoulder, s.elbow, s.hand),
                                                  ("far", s.farShoulder, s.farElbow, s.farHand)] {
                let bend = Self.bend(shoulder, elbow, hand) * pictogram.facing
                #expect(bend <= Self.straightTolerance, "\(id) \(side) elbow at \(p): \(bend)")
            }
        }
    }

    /// Guards the guard: the "pelican" push-up knee (bent the wrong way) must read as
    /// negative, and a correctly bent knee as positive.
    @Test func kneeRuleTellsBackwardFromForward() {
        let hip = CGPoint(x: 48, y: 76), ankle = CGPoint(x: 14, y: 91)
        let pelicanKnee = CGPoint(x: 31, y: 80)   // above the hip–ankle line: wrong
        let realKnee = CGPoint(x: 31, y: 87)      // below it, toward the floor: right
        #expect(Self.bend(hip, pelicanKnee, ankle) < -Self.straightTolerance)
        #expect(Self.bend(hip, realKnee, ankle) > Self.straightTolerance)
    }

    // MARK: - Body and scene

    @Test("Bones keep their length through the movement", arguments: ids)
    func bonesKeepLength(id: ExerciseMotion) {
        let pictogram = Self.pictogram(id)
        for p in Self.samples {
            let s = pictogram.skeleton(at: p)
            for (a, b, length) in [(s.shoulder, s.elbow, ExercisePictogram.upperArm),
                                   (s.elbow, s.hand, ExercisePictogram.forearm),
                                   (s.hip, s.knee, ExercisePictogram.thigh),
                                   (s.knee, s.ankle, ExercisePictogram.shin),
                                   (s.farShoulder, s.farElbow, ExercisePictogram.upperArm),
                                   (s.farElbow, s.farHand, ExercisePictogram.forearm),
                                   (s.farHip, s.farKnee, ExercisePictogram.thigh),
                                   (s.farKnee, s.farAnkle, ExercisePictogram.shin)] {
                #expect(abs(Self.distance(a, b) - length) < 0.01, "\(id) bone length at \(p)")
            }
        }
    }

    @Test("Hands and feet reach their targets", arguments: ids)
    func limbsReachTargets(id: ExerciseMotion) {
        // A target out of reach gets silently clamped by the IK, which leaves a hand
        // hovering over the floor or a foot floating; allow only a sliver.
        let pictogram = Self.pictogram(id)
        var poses = [(CGFloat(0), pictogram.start), (1, pictogram.end)]
        if let mid = pictogram.mid { poses.append((0.5, mid)) }
        for (p, pose) in poses {
            let s = pictogram.skeleton(at: p)
            #expect(Self.distance(s.hand, pose.hand) < 1, "\(id) hand misses its target at \(p)")
            #expect(Self.distance(s.ankle, pose.foot) < 1, "\(id) foot misses its target at \(p)")
            if let farHand = pose.farHand {
                #expect(Self.distance(s.farHand, farHand) < 1, "\(id) far hand misses at \(p)")
            }
            if let farFoot = pose.farFoot {
                #expect(Self.distance(s.farAnkle, farFoot) < 1, "\(id) far foot misses at \(p)")
            }
        }
    }

    @Test("Nothing sinks into the floor or leaves the frame", arguments: ids)
    func staysInScene(id: ExerciseMotion) {
        let pictogram = Self.pictogram(id)
        for p in Self.samples {
            let s = pictogram.skeleton(at: p)
            let joints = [s.hip, s.shoulder, s.elbow, s.hand, s.knee, s.ankle, s.toe,
                          s.farElbow, s.farHand, s.farKnee, s.farAnkle, s.farToe]
            for point in joints.map(pictogram.toView) {
                #expect(point.y <= ExercisePictogram.floorY + 0.5, "\(id) below the floor at \(p)")
                #expect((0...100).contains(point.x), "\(id) leaves the frame at \(p)")
            }
            let head = pictogram.toView(s.headCenter)
            let radius = ExercisePictogram.headRadius * pictogram.viewScale
            #expect(head.y - radius >= 0, "\(id) head cut off at \(p)")
            #expect((radius...(100 - radius)).contains(head.x), "\(id) head cut off at \(p)")
        }
    }
}
