//
//  FrontExercisePictogram.swift
//  MuscleCheck
//
//  The front view, for movements a side view can't show: anything that opens the arms
//  sideways (lateral raise, flyes, rear delt fly) or lifts a leg out (hip abduction).
//  Same 100×100 space, layers and two-bone IK as ExercisePictogram, but the figure
//  faces the viewer and is mirror-symmetric: a pose sets the screen-right hand and
//  foot and the left side mirrors them around x = 50.
//

import CoreGraphics

/// A key pose seen from the front. Points are screen-right side, in view space.
struct FrontPictogramPose {
    var hipY: CGFloat = 54
    /// 1 upright; less when the torso leans toward the viewer (bent over), so it
    /// shows foreshortened.
    var torsoScale: CGFloat = 1
    /// How far the shoulders rise toward the ears (shrug). The head stays put.
    var shrug: CGFloat = 0
    /// Moves the head down from its upright place (bent over, looking at the floor).
    var headDrop: CGFloat = 0
    var hand: CGPoint
    var foot = CGPoint(x: 57, y: FrontPictogram.floorY - 2)
    /// The screen-left foot when the legs don't mirror (hip abduction).
    var leftFoot: CGPoint? = nil
    /// Thighs pointing at the viewer: the knees sit just below the hips.
    var seated = false
}

enum FrontPictogramProp {
    /// Thin static line (posts, cable towers).
    case line(CGPoint, CGPoint)
    /// A solid block (a seat, a bench seen from above).
    case box(CGRect)
    /// Dumbbells seen end-on, one in each hand.
    case dumbbellsAtHands
    /// Dumbbells lying head-to-foot (a fly seen from above).
    case dumbbellsAlongBody
    /// A barbell across both hands.
    case barAtHands
    /// Cables from a pulley on each side to the hands; `pulley` is the right one.
    case cablesToHands(pulley: CGPoint)
    /// Upright pads against the forearms (pec deck).
    case padsOnForearms
}

/// Joint positions for one frame, in view space.
struct FrontPictogramSkeleton {
    struct Limb { let root, joint, end: CGPoint }
    let hipCenter, shoulderCenter, headCenter: CGPoint
    let rightArm, leftArm, rightLeg, leftLeg: Limb
}

struct FrontPictogram {
    static let floorY = ExercisePictogram.floorY
    /// Half the distance between the shoulder joints and between the hip joints. The
    /// shoulders sit just outside the torso so arms at the sides don't merge with it.
    static let shoulderHalf: CGFloat = 11, hipHalf: CGFloat = 6

    let start: FrontPictogramPose
    let end: FrontPictogramPose
    /// Which way the elbows fold: -1 out and up, away from the body (the usual).
    var armBend: CGFloat = -1
    /// Which way the knees fold: -1 out, over the toes.
    var legBend: CGFloat = -1
    /// Off for a view from above (a fly lying on a bench), where there's no floor.
    var showsFloor = true
    let props: [FrontPictogramProp]

    // MARK: - Pose → skeleton

    func skeleton(at progress: CGFloat) -> FrontPictogramSkeleton {
        let a = start, b = end, t = progress
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * t }

        let hipCenter = CGPoint(x: 50, y: mix(a.hipY, b.hipY))
        let torso = ExercisePictogram.torso * mix(a.torsoScale, b.torsoScale)
        let shoulderCenter = hipCenter + CGPoint(x: 0, y: -torso - mix(a.shrug, b.shrug))
        let headCenter = hipCenter + CGPoint(
            x: 0,
            y: -torso - ExercisePictogram.neck - ExercisePictogram.headRadius + mix(a.headDrop, b.headDrop))

        let rightShoulder = shoulderCenter + CGPoint(x: Self.shoulderHalf, y: 0)
        let rightHip = hipCenter + CGPoint(x: Self.hipHalf, y: 0)
        let rootA = Self.shoulders(of: a), rootB = Self.shoulders(of: b)
        let hand = ExercisePictogram.target(a.hand, b.hand, rootA: rootA, rootB: rootB, root: rightShoulder, t)
        let rightArm = Self.limb(root: rightShoulder, target: hand, ExercisePictogram.upperArm,
                                 ExercisePictogram.forearm, bend: armBend)

        let hipA = CGPoint(x: 50 + Self.hipHalf, y: a.hipY), hipB = CGPoint(x: 50 + Self.hipHalf, y: b.hipY)
        let rightLeg = leg(root: rightHip, a.foot, b.foot, hipA, hipB, seatedA: a.seated, seatedB: b.seated,
                           bend: legBend, t)

        let leftLeg: FrontPictogramSkeleton.Limb
        if a.leftFoot != nil || b.leftFoot != nil {
            let mirroredHip = { (p: CGPoint) in CGPoint(x: 100 - p.x, y: p.y) }
            leftLeg = leg(root: mirroredHip(rightHip),
                          a.leftFoot ?? mirroredHip(a.foot), b.leftFoot ?? mirroredHip(b.foot),
                          mirroredHip(hipA), mirroredHip(hipB), seatedA: a.seated, seatedB: b.seated,
                          bend: -legBend, t)
        } else {
            leftLeg = Self.mirror(rightLeg)
        }

        return FrontPictogramSkeleton(hipCenter: hipCenter, shoulderCenter: shoulderCenter,
                                      headCenter: headCenter, rightArm: rightArm,
                                      leftArm: Self.mirror(rightArm), rightLeg: rightLeg, leftLeg: leftLeg)
    }

    private func leg(root: CGPoint, _ footA: CGPoint, _ footB: CGPoint, _ hipA: CGPoint, _ hipB: CGPoint,
                     seatedA: Bool, seatedB: Bool, bend: CGFloat, _ t: CGFloat) -> FrontPictogramSkeleton.Limb {
        let foot = ExercisePictogram.target(footA, footB, rootA: hipA, rootB: hipB, root: root, t)
        if seatedA || seatedB {
            // The thigh points at the viewer: only a short stub of it shows.
            let side: CGFloat = root.x > 50 ? 1 : -1
            return .init(root: root, joint: root + CGPoint(x: 2 * side, y: 6), end: foot)
        }
        return Self.limb(root: root, target: foot, ExercisePictogram.thigh, ExercisePictogram.shin, bend: bend)
    }

    private static func shoulders(of pose: FrontPictogramPose) -> CGPoint {
        CGPoint(x: 50 + shoulderHalf, y: pose.hipY - ExercisePictogram.torso * pose.torsoScale - pose.shrug)
    }

    private static func limb(root: CGPoint, target: CGPoint, _ l1: CGFloat, _ l2: CGFloat,
                             bend: CGFloat) -> FrontPictogramSkeleton.Limb {
        let (joint, end) = ExercisePictogram.solveIK(root: root, target: target, l1: l1, l2: l2, bend: bend)
        return .init(root: root, joint: joint, end: end)
    }

    private static func mirror(_ limb: FrontPictogramSkeleton.Limb) -> FrontPictogramSkeleton.Limb {
        func m(_ p: CGPoint) -> CGPoint { CGPoint(x: 100 - p.x, y: p.y) }
        return .init(root: m(limb.root), joint: m(limb.joint), end: m(limb.end))
    }

    // MARK: - Shapes

    /// Everything to paint for one frame, back to front, in view space.
    func shapes(at progress: CGFloat) -> [PictogramShape] {
        let s = skeleton(at: progress)
        let hands = [s.rightArm, s.leftArm]
        var out: [PictogramShape] = []
        func add(_ path: CGPath, _ layer: PictogramShape.Layer, _ paint: PictogramShape.Paint = .fill) {
            out.append(.init(path: path, layer: layer, paint: paint))
        }

        if showsFloor {
            add(ExercisePictogram.polyline([.init(x: 4, y: Self.floorY + 1.5), .init(x: 96, y: Self.floorY + 1.5)]),
                .equipment, .stroke(1.5))
        }

        // Behind the body.
        for prop in props {
            switch prop {
            case .line(let a, let b): add(ExercisePictogram.polyline([a, b]), .equipment, .stroke(2.5))
            case .box(let rect):
                add(CGPath(roundedRect: rect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil), .equipment)
            case .cablesToHands(let pulley):
                for (arm, p) in zip(hands, [pulley, CGPoint(x: 100 - pulley.x, y: pulley.y)]) {
                    add(ExercisePictogram.circle(p, 3), .equipment)
                    add(ExercisePictogram.polyline([p, arm.end]), .equipment, .stroke(1))
                }
            case .padsOnForearms:
                for arm in hands {
                    add(ExercisePictogram.capsule(arm.joint, arm.end + ExercisePictogram.unit(arm.end - arm.joint) * 3,
                                                  7, 7), .equipment)
                }
            case .dumbbellsAtHands:
                for arm in hands { add(ExercisePictogram.circle(arm.end, 4.5), .equipment) }
            case .barAtHands:
                let l = s.leftArm.end, r = s.rightArm.end
                add(ExercisePictogram.circle(l + CGPoint(x: -9, y: 0), 6), .equipmentBack)
                add(ExercisePictogram.circle(r + CGPoint(x: 9, y: 0), 6), .equipmentBack)
            case .dumbbellsAlongBody: break
            }
        }

        // Legs, torso and head, then the arms over them.
        for leg in [s.leftLeg, s.rightLeg] {
            let toe = leg.end + CGPoint(x: leg.root.x > 50 ? 2.5 : -2.5, y: 1)
            add(ExercisePictogram.capsule(leg.root, leg.joint, 8.5, 6.5), .figure)
            add(ExercisePictogram.capsule(leg.joint, leg.end, 6.5, 4.5), .figure)
            add(ExercisePictogram.capsule(leg.end, toe, 4.5, 3.5), .figure)
        }
        add(ExercisePictogram.capsule(s.hipCenter, s.shoulderCenter, 14, 18), .figure)
        add(ExercisePictogram.circle(s.headCenter, ExercisePictogram.headRadius), .figure)
        for arm in hands {
            add(ExercisePictogram.capsule(arm.root, arm.joint, 6.5, 5), .figure)
            add(ExercisePictogram.capsule(arm.joint, arm.end, 5, 4), .figure)
            add(ExercisePictogram.circle(arm.end, 2.8), .figure)
        }

        // In the hands, in front.
        for prop in props {
            switch prop {
            case .barAtHands:
                let l = s.leftArm.end, r = s.rightArm.end
                add(ExercisePictogram.capsule(l + CGPoint(x: -9, y: 0), r + CGPoint(x: 9, y: 0), 2.5, 2.5),
                    .equipment)
            case .dumbbellsAlongBody:
                for arm in hands {
                    add(ExercisePictogram.capsule(arm.end + CGPoint(x: 0, y: -6), arm.end + CGPoint(x: 0, y: 6),
                                                  4, 4), .equipment)
                }
            default: break
            }
        }
        return out
    }
}
