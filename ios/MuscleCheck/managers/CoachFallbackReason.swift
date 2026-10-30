//
//  CoachFallbackReason.swift
//  MuscleCheck
//
//  Why a coach suggestion fell back from Private Cloud Compute to the on-device
//  model. Sent to analytics: it's the only real-world measure of how PCC holds up.
//

import Foundation
import FoundationModels

enum CoachFallbackReason: String, CaseIterable {
    /// PCC isn't available on this device/OS right now, so it wasn't tried.
    case unavailable
    /// The user's daily PCC quota is used up (checked before the request, or thrown).
    case quota
    case network
    /// PCC reported its service as unavailable.
    case service
    /// No answer within the deadline (see `withTimeout`).
    case timeout
    /// The answer failed our checks: empty, fewer than 2 valid groups, or a copied
    /// group name that doesn't match the index.
    case invalid
    /// Guardrail violation or refusal.
    case rejected
    case other
}

@available(iOS 27, *)
extension CoachFallbackReason {

    init(_ error: Error) {
        switch error {
        case let error as PrivateCloudComputeLanguageModel.Error:
            switch error {
            case .networkFailure: self = .network
            case .quotaLimitReached: self = .quota
            case .serviceUnavailable: self = .service
            @unknown default: self = .other
            }
        case is TimeoutError:
            self = .timeout
        case is RoutineSuggestionError:
            self = .invalid
        // iOS 27 replaces LanguageModelSession.GenerationError with LanguageModelError.
        case let error as LanguageModelError:
            switch error {
            case .guardrailViolation, .refusal: self = .rejected
            case .timeout: self = .timeout
            default: self = .other
            }
        default:
            self = .other
        }
    }
}
