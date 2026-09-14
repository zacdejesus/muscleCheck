//
//  RoutineTextGateTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  The pre-check that rejects photos that can't be a routine before the model invents one.
//  The rule is tested on text; the evaluation images check the real Vision reading (Vision runs
//  in the simulator, unlike the on-device model).
//

import Testing
@testable import MuscleCheck
import Foundation
import UIKit

private final class GateBundleToken {}

struct RoutineTextGateTests {

    @Test
    func noReadableLinesIsNoText() {
        #expect(RoutineTextGate.verdict(forLines: []) == .noText)
        #expect(RoutineTextGate.verdict(forLines: ["  ", ""]) == .noText)
    }

    @Test(arguments: [["Algo 4x8"], ["3 × 12"], ["Sentadilla"], ["4 series de 10 repeticiones"], ["RUTINA GLÚTEOS"], ["Cinta 20 min"]])
    func routineSignalsPass(lines: [String]) {
        #expect(RoutineTextGate.verdict(forLines: lines) == .looksLikeRoutine)
    }

    @Test(arguments: [["Súper", "Leche x2", "Huevos 12", "Pan", "Pollo 2kg", "Bananas 6"], ["Reunión de equipo", "Llamar a Juan 15:30"]])
    func textWithoutRoutineSignalsIsRejected(lines: [String]) {
        #expect(RoutineTextGate.verdict(forLines: lines) == .notARoutine)
    }

    private struct EvalCase: Decodable {
        let id: String
        let file: String
        let expectNothing: Bool?
        let notation: String?
    }

    /// Real Vision on the 32 evaluation images: no real routine may be rejected. Prints every
    /// verdict so negatives can be read in the log.
    @Test
    func noRoutineFromTheEvaluationSetIsRejected() async throws {
        let bundle = Bundle(for: GateBundleToken.self)
        let manifest = try #require(bundle.url(forResource: "scaneval_manifest", withExtension: "json"))
        let cases = try JSONDecoder().decode([EvalCase].self, from: Data(contentsOf: manifest))
        var rejected: [String] = []
        for evalCase in cases {
            let path = try #require(bundle.path(forResource: (evalCase.file as NSString).deletingPathExtension, ofType: "jpg"))
            let image = try #require(UIImage(contentsOfFile: path)?.cgImage)
            let verdict = await RoutineTextGate.check(image)
            print("GATE \(evalCase.id) \(verdict)")
            let isRoutine = !(evalCase.expectNothing ?? false) && evalCase.notation != "unreadable"
            if isRoutine && verdict != .looksLikeRoutine { rejected.append("\(evalCase.id) → \(verdict)") }
        }
        #expect(rejected.isEmpty, "rutinas rechazadas: \(rejected)")
    }
}
