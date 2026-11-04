//
//  ExercisePictogram.swift
//  MuscleCheck
//
//  A pictogram-style exercise animation drawn in code (no image assets, no licensed
//  media). Each exercise is two (or three) key poses in a 100×100 side view; the
//  figure interpolates between them and two-bone IK places elbows and knees. Pure
//  CoreGraphics, no UIKit/SwiftUI, so it is unit-testable and any renderer draws the
//  exact same shapes. The exercises live in ExercisePictogramCatalog.
//

import CoreGraphics
import Foundation

/// A key pose. Angles are in degrees in screen space: 0 = right, 90 = down.
struct PictogramPose {
    var hip: CGPoint
    var torsoAngle: CGFloat
    var hand: CGPoint
    var foot: CGPoint
    /// The far-side hand / foot when it does something different from the near one
    /// (lunge, one-arm row). nil: the far limb copies the near one, nudged back.
    var farHand: CGPoint? = nil
    var farFoot: CGPoint? = nil
    /// Absolute foot angle in degrees (calf raise). nil: foot square to the shin.
    var footAngle: CGFloat? = nil
}

enum PictogramProp {
    /// Thin static line (bench legs, posts).
    case line(CGPoint, CGPoint)
    /// Thick static bar with rounded ends (pads, bars, towers).
    case beam(CGPoint, CGPoint, width: CGFloat)
    /// A solid block (a step, a plyo box).
    case box(CGRect)
    /// A barbell seen end-on: a plate that follows the hand.
    case plateAtHand(radius: CGFloat)
    /// A barbell resting on the upper back (squat).
    case plateAtShoulder(radius: CGFloat)
    /// A dumbbell in the hand, seen from the side.
    case dumbbellAtHand
    /// A dumbbell held in a neutral grip: across the forearm (hammer curl).
    case hammerDumbbellAtHand
    /// An ab wheel under the hand.
    case wheelAtHand(radius: CGFloat)
    /// A cable from a fixed pulley to the hand.
    case cableToHand(pulley: CGPoint)
    /// A barbell anchored at a floor pivot, its free end in the hand (landmine).
    case barToHand(pivot: CGPoint)
    /// A roller pad at the ankle (leg extension, leg curl).
    case padAtFoot(radius: CGFloat)
    /// A sled on a fixed rail (45° leg press): the footplate square to the rail under
    /// the soles, and a weight plate loaded behind it.
    case sledOnRail(from: CGPoint, to: CGPoint)
}

/// Joint positions for one frame, in model space.
struct PictogramSkeleton {
    let hip, shoulder, headCenter: CGPoint
    let elbow, hand, knee, ankle, toe: CGPoint
    let farShoulder, farHip: CGPoint
    let farElbow, farHand, farKnee, farAnkle, farToe: CGPoint
}

/// What to paint, back to front. The renderer picks the colour per layer.
struct PictogramShape {
    enum Layer { case equipmentBack, equipment, figureFar, figure }
    enum Paint { case fill, stroke(CGFloat) }
    let path: CGPath
    let layer: Layer
    let paint: Paint
}

struct ExercisePictogram {
    let start: PictogramPose
    /// Optional pose half-way through, for curved paths (curls, raises).
    var mid: PictogramPose? = nil
    let end: PictogramPose
    /// +1 when the chest faces clockwise from the torso direction (a figure facing
    /// right, or lying face up with the head to the left). It fixes which way elbows
    /// and knees bend, so no exercise can configure an impossible joint.
    var facing: CGFloat = 1
    /// Zoom around the floor's centre, for movements that go above the head.
    var viewScale: CGFloat = 1
    /// A longer foot reads better when the foot is the movement (calf raise).
    var footLength: CGFloat = 5
    let props: [PictogramProp]

    static let torso: CGFloat = 30, neck: CGFloat = 4.5, headRadius: CGFloat = 6.5
    static let upperArm: CGFloat = 15, forearm: CGFloat = 14
    static let thigh: CGFloat = 19, shin: CGFloat = 19
    static let floorY: CGFloat = 94
    /// Where the far-side limbs hang from, relative to the near ones (depth).
    static let farOffset = CGPoint(x: -1.8, y: -1.2)

    // MARK: - Pose → skeleton

    /// `progress` 0 = start pose, 1 = end pose (through `mid` at 0.5, if any).
    func skeleton(at progress: CGFloat) -> PictogramSkeleton {
        let (a, b, t) = segment(progress)
        let hip = Self.hipPath(a, b, t)
        let angle = (a.torsoAngle + (b.torsoAngle - a.torsoAngle) * t) * .pi / 180
        let dir = CGPoint(x: cos(angle), y: sin(angle))
        let shoulder = hip + dir * Self.torso
        let head = shoulder + dir * (Self.neck + Self.headRadius)

        let handTarget = Self.target(a.hand, b.hand, rootA: Self.shoulder(of: a),
                                     rootB: Self.shoulder(of: b), root: shoulder, t)
        let footTarget = Self.target(a.foot, b.foot, rootA: a.hip, rootB: b.hip, root: hip, t)
        let footAngle = Self.lerpOptional(a.footAngle, b.footAngle, t)

        let (elbow, hand) = Self.solveIK(root: shoulder, target: handTarget,
                                         l1: Self.upperArm, l2: Self.forearm, bend: facing)
        let (knee, ankle) = Self.solveIK(root: hip, target: footTarget,
                                         l1: Self.thigh, l2: Self.shin, bend: -facing)
        let toe = toePoint(knee: knee, ankle: ankle, angle: footAngle)

        let back = CGPoint(x: Self.farOffset.x * facing, y: Self.farOffset.y)
        let farShoulder = shoulder + back, farHip = hip + back

        let farElbow: CGPoint, farHand: CGPoint
        if a.farHand != nil || b.farHand != nil {
            let target = Self.target(a.farHand ?? a.hand, b.farHand ?? b.hand,
                                     rootA: Self.shoulder(of: a) + back,
                                     rootB: Self.shoulder(of: b) + back, root: farShoulder, t)
            (farElbow, farHand) = Self.solveIK(root: farShoulder, target: target,
                                               l1: Self.upperArm, l2: Self.forearm, bend: facing)
        } else {
            (farElbow, farHand) = (elbow + back, hand + back)
        }

        let farKnee: CGPoint, farAnkle: CGPoint, farToe: CGPoint
        if a.farFoot != nil || b.farFoot != nil {
            let target = Self.target(a.farFoot ?? a.foot, b.farFoot ?? b.foot,
                                     rootA: a.hip + back, rootB: b.hip + back, root: farHip, t)
            (farKnee, farAnkle) = Self.solveIK(root: farHip, target: target,
                                               l1: Self.thigh, l2: Self.shin, bend: -facing)
            farToe = toePoint(knee: farKnee, ankle: farAnkle, angle: footAngle)
        } else {
            (farKnee, farAnkle, farToe) = (knee + back, ankle + back, toe + back)
        }

        return PictogramSkeleton(hip: hip, shoulder: shoulder, headCenter: head,
                                 elbow: elbow, hand: hand, knee: knee, ankle: ankle, toe: toe,
                                 farShoulder: farShoulder, farHip: farHip,
                                 farElbow: farElbow, farHand: farHand, farKnee: farKnee,
                                 farAnkle: farAnkle, farToe: farToe)
    }

    /// Model space → the 100×100 view (applies `viewScale` around the floor centre).
    func toView(_ p: CGPoint) -> CGPoint {
        CGPoint(x: 50 + (p.x - 50) * viewScale, y: Self.floorY + (p.y - Self.floorY) * viewScale)
    }

    private func segment(_ p: CGFloat) -> (PictogramPose, PictogramPose, CGFloat) {
        guard let mid else { return (start, end, p) }
        return p < 0.5 ? (start, mid, p * 2) : (mid, end, (p - 0.5) * 2)
    }

    /// The foot: square to the shin, toward where the figure faces, unless the pose
    /// sets an absolute angle.
    private func toePoint(knee: CGPoint, ankle: CGPoint, angle: CGFloat?) -> CGPoint {
        if let angle {
            let r = angle * .pi / 180
            return ankle + CGPoint(x: cos(r) * facing, y: sin(r)) * footLength
        }
        let shinDir = (ankle - knee) * (1 / Self.shin)
        return ankle + CGPoint(x: shinDir.y * facing, y: -shinDir.x * facing) * footLength
    }

    // MARK: - Shapes

    /// Everything to paint for one frame, back to front, in view space.
    func shapes(at progress: CGFloat) -> [PictogramShape] {
        let s = skeleton(at: progress)
        var out: [PictogramShape] = []
        var transform = CGAffineTransform(translationX: 50, y: Self.floorY)
            .scaledBy(x: viewScale, y: viewScale)
            .translatedBy(x: -50, y: -Self.floorY)
        func add(_ path: CGPath, _ layer: PictogramShape.Layer, _ paint: PictogramShape.Paint = .fill) {
            out.append(.init(path: path.copy(using: &transform) ?? path, layer: layer, paint: paint))
        }

        // The floor stays full width whatever the zoom.
        out.append(.init(path: Self.polyline([.init(x: 4, y: Self.floorY + 1.5),
                                              .init(x: 96, y: Self.floorY + 1.5)]),
                         layer: .equipment, paint: .stroke(1.5)))

        // Behind the body.
        for prop in props {
            switch prop {
            case .plateAtHand(let r): add(Self.circle(s.hand, r), .equipmentBack)
            case .plateAtShoulder(let r): add(Self.circle(s.shoulder, r), .equipmentBack)
            case .line(let a, let b): add(Self.polyline([a, b]), .equipment, .stroke(2.5))
            case .beam(let a, let b, let w): add(Self.capsule(a, b, w, w), .equipment)
            case .box(let rect):
                add(CGPath(roundedRect: rect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil), .equipment)
            case .cableToHand(let pulley):
                add(Self.circle(pulley, 3), .equipment)
                add(Self.polyline([pulley, s.hand]), .equipment, .stroke(1))
            case .padAtFoot(let r): add(Self.circle(s.ankle, r), .equipment)
            case .barToHand(let pivot):
                add(Self.capsule(pivot, s.hand, 3, 3), .equipment)
                add(Self.circle(s.hand + Self.unit(pivot - s.hand) * 7, 6), .equipmentBack)
            case .sledOnRail(let from, let to):
                let along = Self.unit(to - from)
                let across = CGPoint(x: -along.y, y: along.x)
                add(Self.capsule(from, to, 3, 3), .equipment)
                let plate = (s.ankle + s.toe) * 0.5 + along * 2.5
                add(Self.circle(plate + along * 7, 6.5), .equipmentBack)
                add(Self.capsule(plate - across * 9, plate + across * 9, 4, 4), .equipment)
            case .dumbbellAtHand, .hammerDumbbellAtHand, .wheelAtHand: break
            }
        }

        // Far arm and leg, lighter, for depth.
        for path in limbPaths(s.farShoulder, s.farElbow, s.farHand,
                              s.farHip, s.farKnee, s.farAnkle, s.farToe) {
            add(path, .figureFar)
        }

        // Body: tapered torso, neck gap, head; then the near limbs.
        add(Self.capsule(s.hip, s.shoulder, 9, 11.5), .figure)
        add(Self.circle(s.headCenter, Self.headRadius), .figure)
        for path in limbPaths(s.shoulder, s.elbow, s.hand, s.hip, s.knee, s.ankle, s.toe) {
            add(path, .figure)
        }

        // In the hand, in front.
        for prop in props {
            switch prop {
            case .dumbbellAtHand:
                add(CGPath(roundedRect: CGRect(x: s.hand.x - 6, y: s.hand.y - 3, width: 12, height: 6),
                           cornerWidth: 2, cornerHeight: 2, transform: nil), .equipment)
            case .hammerDumbbellAtHand:
                let across = Self.unit(s.hand - s.elbow)
                let n = CGPoint(x: -across.y, y: across.x) * 6
                add(Self.capsule(s.hand - n, s.hand + n, 5, 5), .equipment)
            case .wheelAtHand(let r):
                add(Self.circle(s.hand + CGPoint(x: 0, y: r - 2), r), .equipment)
            default: break
            }
        }
        return out
    }

    /// Upper arm, forearm, hand, thigh, shin and foot: tapered like real limbs.
    private func limbPaths(_ shoulder: CGPoint, _ elbow: CGPoint, _ hand: CGPoint,
                           _ hip: CGPoint, _ knee: CGPoint, _ ankle: CGPoint,
                           _ toe: CGPoint) -> [CGPath] {
        [
            Self.capsule(hip, knee, 8.5, 6.5),
            Self.capsule(knee, ankle, 6.5, 4.5),
            Self.capsule(ankle, toe, 4.5, 3.5),
            Self.capsule(shoulder, elbow, 6.5, 5),
            Self.capsule(elbow, hand, 5, 4),
            Self.circle(hand, 2.8),
        ]
    }

    /// Ping-pong with an eased hold at both ends, for a looping animation.
    static func progress(time: TimeInterval, period: TimeInterval) -> CGFloat {
        let u = time.truncatingRemainder(dividingBy: period) / period
        let tri = CGFloat(u < 0.5 ? u * 2 : (1 - u) * 2)
        return tri * tri * (3 - 2 * tri)
    }

    // MARK: - Interpolation

    private static func shoulder(of pose: PictogramPose) -> CGPoint {
        let r = pose.torsoAngle * .pi / 180
        return pose.hip + CGPoint(x: cos(r), y: sin(r)) * torso
    }

    /// With the foot planted in both poses the hip swings on an arc around it, so a
    /// leg at full reach stays straight mid-movement (a straight lerp cuts the chord
    /// and folds the knee). Otherwise a plain lerp.
    private static func hipPath(_ a: PictogramPose, _ b: PictogramPose, _ t: CGFloat) -> CGPoint {
        guard a.foot == b.foot else { return lerp(a.hip, b.hip, t) }
        return a.foot + polarLerp(a.hip - a.foot, b.hip - b.foot, t)
    }

    /// A hand or foot target. Fixed in the world when it doesn't move (hands on a bar,
    /// feet on the floor); otherwise it sweeps around its root (shoulder or hip), so
    /// a straight arm or leg stays straight instead of cutting a chord.
    private static func target(_ a: CGPoint, _ b: CGPoint, rootA: CGPoint, rootB: CGPoint,
                               root: CGPoint, _ t: CGFloat) -> CGPoint {
        guard a != b else { return a }
        return root + polarLerp(a - rootA, b - rootB, t)
    }

    /// Interpolates two offsets by angle (the short way round) and length.
    private static func polarLerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let ra = hypot(a.x, a.y), rb = hypot(b.x, b.y)
        let angleA = atan2(a.y, a.x)
        var delta = atan2(b.y, b.x) - angleA
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        let angle = angleA + delta * t
        return CGPoint(x: cos(angle), y: sin(angle)) * (ra + (rb - ra) * t)
    }

    private static func lerpOptional(_ a: CGFloat?, _ b: CGFloat?, _ t: CGFloat) -> CGFloat? {
        guard let a, let b else { return a ?? b }
        return a + (b - a) * t
    }

    // MARK: - Geometry

    /// Two-bone IK: the middle joint for a limb reaching `target` (clamped to reach).
    private static func solveIK(root: CGPoint, target: CGPoint, l1: CGFloat, l2: CGFloat,
                                bend: CGFloat) -> (joint: CGPoint, end: CGPoint) {
        let delta = target - root
        let raw = max(hypot(delta.x, delta.y), 0.001)
        let d = min(max(raw, abs(l1 - l2) + 0.01), l1 + l2 - 0.01)
        let base = atan2(delta.y, delta.x)
        let a = acos((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))
        let jointAngle = base + bend * a
        let joint = root + CGPoint(x: cos(jointAngle), y: sin(jointAngle)) * l1
        let end = root + CGPoint(x: cos(base), y: sin(base)) * d
        return (joint, end)
    }

    /// A segment with round ends whose width goes from `w1` at `a` to `w2` at `b`.
    private static func capsule(_ a: CGPoint, _ b: CGPoint, _ w1: CGFloat, _ w2: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let n = unit(b - a)
        let normal = CGPoint(x: -n.y, y: n.x)
        let r1 = w1 / 2, r2 = w2 / 2
        path.move(to: a + normal * r1)
        path.addLine(to: b + normal * r2)
        path.addLine(to: b - normal * r2)
        path.addLine(to: a - normal * r1)
        path.closeSubpath()
        // Union, not plain subpaths: overlapping subpaths with opposite winding
        // would punch holes at the joints.
        return path
            .union(circle(a, r1))
            .union(circle(b, r2))
    }

    private static func circle(_ c: CGPoint, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil)
    }

    private static func polyline(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        return path
    }

    private static func unit(_ p: CGPoint) -> CGPoint {
        let len = max(hypot(p.x, p.y), 0.001)
        return CGPoint(x: p.x / len, y: p.y / len)
    }
}

// MARK: - Point math

private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}
private func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
private func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
private func * (a: CGPoint, k: CGFloat) -> CGPoint { CGPoint(x: a.x * k, y: a.y * k) }
