//
//  RoutineScanning.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  The seam between the scan UI and the model that reads the photo (Dependency
//  Inversion): the view model depends on this protocol, never on FoundationModels.
//  Everything here is version-agnostic, so the iOS 18 target can hold an
//  `any RoutineScanning` — no `Any?` storage trick like RoutineCoachViewModel needs —
//  while the only production conformer is iOS 27+. Tests inject a mock and drive the
//  whole flow without a device or the model.
//

import CoreGraphics

enum RoutineScanAvailability: Equatable {
    case available
    /// Eligible device with Apple Intelligence on; the model is still downloading.
    case modelNotReady
    /// Won't resolve by waiting: iOS < 27, ineligible device, Apple Intelligence off, or
    /// a model without image input. The home entry point stays hidden.
    case unavailable
}

enum RoutineScanError: Error, Equatable {
    /// Vision found no text at all in the photo (blank page, photo without text, too blurry).
    case noText
    /// The photo has text, but nothing of a routine in it (a shopping list, a note).
    case notARoutine
    /// The photo was read but no exercise came out of it.
    case nothingFound
    /// The model failed (guardrails, context window, assets) or produced nothing.
    case failed
}

@MainActor
protocol RoutineScanning {
    var availability: RoutineScanAvailability { get }

    /// Reads a routine from `image`. The user's groups are deliberately NOT passed: the model
    /// names each exercise's muscle and the code maps it (`RoutineImport.groupChoice`).
    /// `onPartial` receives progressively filled snapshots while the model streams, so the
    /// reading screen shows exercises as they appear.
    func scan(
        image: CGImage,
        onPartial: ((ScannedRoutine) -> Void)?
    ) async throws -> ScannedRoutine
}

@MainActor
enum RoutineScanSupport {

    /// The production scanner, or nil on an OS older than iOS 27.
    static func makeScanner() -> (any RoutineScanning)? {
        if #available(iOS 27, *) {
            return FoundationModelsRoutineScanner()
        }
        return nil
    }

    /// Whether the home shows the entry point, without building a scanner.
    static var availability: RoutineScanAvailability {
        if #available(iOS 27, *) {
            return FoundationModelsRoutineScanner.currentAvailability
        }
        return .unavailable
    }
}
