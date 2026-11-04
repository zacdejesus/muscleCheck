//
//  RoutineTextGate.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  A check BEFORE the on-device model: Vision reads the photo's text (on-device, well under a
//  second) and images that can't be a routine are rejected with a clear error. In the iPhone
//  evaluation the model never answered "nothing here": it returned "Leche 1×2" for a shopping
//  list and "bench press, row" for a blank page, and took 5–50 s doing it.
//
//  It fails OPEN: if Vision errors out, the photo goes to the model as before. A real routine
//  must never be blocked by the pre-check itself.
//

import Foundation
import CoreGraphics
import Vision

enum RoutineTextGate {

    enum Verdict: Equatable {
        /// No text at all: blank page, photo without text, or too blurry to read.
        case noText
        /// Text, but nothing of a routine in it (a shopping list, a note).
        case notARoutine
        case looksLikeRoutine
    }

    /// Reads the photo's text and decides. Never throws: a Vision failure lets the photo through.
    static func check(_ image: CGImage) async -> Verdict {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = ["es", "en", "fr", "it"].map { Locale.Language(identifier: $0) }
        guard let observations = try? await request.perform(on: image) else { return .looksLikeRoutine }
        return verdict(forLines: observations.compactMap { $0.topCandidates(1).first?.string })
    }

    /// The decision on recognized lines — pure, so it's unit-tested without images. A routine shows
    /// at least one of: a "sets × reps" pair ("4x8", "3 × 12"), an exercise the catalog knows, or a
    /// training word ("series", "reps", "rutina").
    static func verdict(forLines lines: [String]) -> Verdict {
        let text = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !text.isEmpty else { return .noText }
        let isRoutine = text.contains { line in
            hasSetsTimesReps(line) || isKnownExercise(line) || hasTrainingWord(line)
        }
        return isRoutine ? .looksLikeRoutine : .notARoutine
    }

    /// "4x8", "3 × 12", "4 X 10-12". A lone "x2" ("Leche x2") doesn't count: it needs a number on both sides.
    private static func hasSetsTimesReps(_ line: String) -> Bool {
        line.range(of: #"\d+\s*[xX×*]\s*\d+"#, options: .regularExpression) != nil
    }

    private static func isKnownExercise(_ line: String) -> Bool {
        if case .known = ExerciseCatalog.lookup(line) { return true }
        return false
    }

    private static let trainingWords: Set<String> = [
        "series", "serie", "sets", "reps", "rep", "repeticiones", "repeticion", "rutina", "entrenamiento", "entreno",
        "workout", "routine", "training", "amrap", "descanso", "rest", "seances", "repetitions", "scheda",
        "ripetizioni", "allenamento", "programme",
    ]

    private static func hasTrainingWord(_ line: String) -> Bool {
        NameMatching.fold(line).split(separator: " ").contains { trainingWords.contains(String($0)) }
    }
}
