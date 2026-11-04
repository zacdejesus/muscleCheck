//
//  CoachEngine.swift
//  MuscleCheck
//
//  Which model answers the AI Coach. Private Cloud Compute is preferred (better
//  pairs and exercises, and faster than the on-device model in testing); the
//  on-device model is the fallback when PCC can't be used. See
//  docs/feature12-prompt-tuning.md.
//
//  Returned with each suggestion so the app knows which model answered (analytics).
//

import Foundation

enum CoachEngine: String {
    case privateCloud = "pcc"
    case onDevice = "on_device"
}

/// A coach suggestion and how it was produced.
struct CoachResult: Equatable {
    let suggestion: RoutineSuggestion
    let engine: CoachEngine
    /// Why it fell back to the on-device model; nil when PCC answered or wasn't an
    /// option (iOS 26).
    let fallbackReason: CoachFallbackReason?
}
