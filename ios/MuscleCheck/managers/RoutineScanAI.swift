//
//  RoutineScanAI.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  Reads a workout routine from a photo with the on-device model's image input
//  (FoundationModels, iOS 27+). The model only TRANSCRIBES — names as written, sets, reps
//  verbatim — and names each exercise's muscle from a closed enum. It never sees the user's
//  groups: with the same muscle in two languages ("Back", "Espalda") picking an index from
//  that list was where it went wrong. Validation and every mapping rule live in
//  `RoutineImport`, which is plain testable code.
//
//  Wrapped in `#if compiler(>=6.4)`: the iOS 27 SDK ships with Xcode 27 (Swift 6.4).
//  Older toolchains (Xcode 26 locally, the macos-26 CI runner) skip this file and
//  `RoutineScanSupport` reports the feature as unavailable.
//

#if compiler(>=6.4)
import FoundationModels
import Foundation
import CoreGraphics

/// Raw structured output. Field descriptions stay in English (they describe the schema);
/// values are transcribed in whatever language the sheet is written in.
@available(iOS 27, *)
@Generable
struct ExtractedRoutine {
    @Guide(description: "Every exercise on the routine, in the order it is written")
    var exercises: [ExtractedExercise]
}

@available(iOS 27, *)
@Generable
struct ExtractedExercise {
    @Guide(description: "Exercise name exactly as written, without sets, reps or weight")
    var name: String
    @Guide(description: "Number of sets: the FIRST number of 'sets x reps' (4 in '4x8'), or null if not written or unreadable")
    var sets: Int?
    @Guide(description: "Repetitions: the SECOND part of 'sets x reps' (8 in '4x8', 10-12 in '3x10-12'), exactly as written, or null if not written or unreadable")
    var reps: String?
    @Guide(description: "Main muscle group this exercise trains. Use other for cardio, full-body movements or when unsure")
    var muscle: ExtractedMuscle
    @Guide(description: "Muscle group or heading written above this exercise on the sheet, or null")
    var writtenGroup: String?
    @Guide(description: "low if any field was hard to read or had to be guessed, otherwise high")
    var confidence: ReadConfidence
}

/// Closed set: constrained decoding can't produce an out-of-range index or an invented group.
@available(iOS 27, *)
@Generable
enum ExtractedMuscle {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case legs
    case glutes
    case calves
    case core
    case forearms
    case other
}

@available(iOS 27, *)
@Generable
enum ReadConfidence {
    case high
    case low
}

@available(iOS 27, *)
@MainActor
final class FoundationModelsRoutineScanner: RoutineScanning {

    private static var model: SystemLanguageModel { .default }

    /// Three gates: the OS (the `@available` above), the model's availability, and its
    /// image capability — an available model isn't necessarily one that accepts images.
    static var currentAvailability: RoutineScanAvailability {
        switch model.availability {
        case .available:
            return model.capabilities.contains(.vision) ? .available : .unavailable
        case .unavailable(.modelNotReady):
            return .modelNotReady
        case .unavailable:
            return .unavailable
        }
    }

    var availability: RoutineScanAvailability { Self.currentAvailability }

    func scan(
        image: CGImage,
        onPartial: ((ScannedRoutine) -> Void)?
    ) async throws -> ScannedRoutine {
        // A fresh session per scan: nothing to remember between photos, and an old
        // transcript would only eat the context window.
        let session = LanguageModelSession(model: Self.model, instructions: Self.instructions)

        var options = GenerationOptions()
        // Transcription, not creativity: always the most likely reading.
        options.samplingMode = .greedy
        options.maximumResponseTokens = 2000

        let stream = session.streamResponse(generating: ExtractedRoutine.self, options: options) {
            "Extract the workout routine from this image."
            Attachment<ImageAttachmentContent>(image)
        }

        var latest: ExtractedRoutine.PartiallyGenerated?
        do {
            for try await snapshot in stream {
                latest = snapshot.content
                onPartial?(Self.resolve(snapshot.content))
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw RoutineScanError.failed
        }

        guard let latest else { throw RoutineScanError.failed }
        let routine = Self.resolve(latest)
        guard !routine.items.isEmpty else { throw RoutineScanError.nothingFound }
        return routine
    }

    private static func targetMuscle(_ muscle: ExtractedMuscle) -> TargetMuscle? {
        switch muscle {
        case .chest: return .chest
        case .back: return .back
        case .shoulders: return .shoulders
        case .biceps: return .biceps
        case .triceps: return .triceps
        case .legs: return .legs
        case .glutes: return .glutes
        case .calves: return .calves
        case .core: return .core
        case .forearms: return .forearms
        case .other: return nil
        }
    }

    private static var instructions: Instructions {
        Instructions {
            "You transcribe workout routines from photos: handwritten sheets, printed or magazine routines, and screenshots."
            "Copy exercise names exactly as written, in the language they are written. Do not translate, correct or invent exercises."
            "Routines are written as sets x reps: in '4x8' the first number is the sets (4) and the second is the reps (8); in '3x10-12' the sets are 3 and the reps are 10-12."
            "A weight written next to them ('80 kg', '@ 80') is neither sets nor reps: ignore it."
            "Never swap the two numbers. If the order looks unusual, like '12x3', still copy the first number as sets and the second as reps, and mark confidence as low."
            "Keep reps exactly as written, including ranges like 8-12."
            "For each exercise choose the main muscle group it trains, from its movement: a leg press or a squat trains legs, a bench press trains chest, a row trains back. Use other for cardio, full-body movements or when unsure."
            "If you cannot read a field with confidence, leave it null and mark confidence as low."
        }
    }

    /// Best-effort mapping of a (possibly partial) snapshot. Rows without a name yet are
    /// dropped; everything else is validated later by `RoutineImport.drafts`.
    private static func resolve(_ partial: ExtractedRoutine.PartiallyGenerated) -> ScannedRoutine {
        let items: [ScannedRoutine.Item] = (partial.exercises ?? []).compactMap { exercise in
            guard let name = exercise.name, !name.isEmpty else { return nil }
            return ScannedRoutine.Item(
                name: name,
                sets: exercise.sets ?? nil,
                repsText: exercise.reps ?? nil,
                muscle: exercise.muscle.flatMap(Self.targetMuscle),
                writtenGroup: exercise.writtenGroup ?? nil,
                lowConfidence: exercise.confidence == .low
            )
        }
        return ScannedRoutine(items: items)
    }
}
#endif
