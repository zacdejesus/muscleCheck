//
//  ScanEvaluationTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  Measures the REAL scanner on 32 synthetic images with known answers (handwritten, PDF,
//  screenshots, negatives). Device only: the on-device model doesn't run in the simulator on a
//  macOS 26 host. It never fails on results — it prints one SCANEVAL_RESULT line per case for
//  tools/scan-eval/score.py. How to run: tools/scan-eval/README.md.
//

#if compiler(>=6.4) && !targetEnvironment(simulator)
import Testing
@testable import MuscleCheck
import FoundationModels
import UIKit

final class ScanEvalBundleToken {}

@MainActor
struct ScanEvaluationTests {
    private let bundle = Bundle(for: ScanEvalBundleToken.self)

    private struct CaseInfo: Decodable { let id: String; let file: String }

    /// The owner's real gym groups: the same muscles in two languages.
    private func ownerGroups() -> [MuscleEntry] {
        let names = ["Abdomen", "Back", "Bicep", "Biceps", "Chest", "Core", "Espalda", "Legs", "Pecho", "Piernas", "Shoulders", "Tricep", "Triceps"]
        return names.map { name in
            let group = MuscleEntry(name: name, category: "gym")
            if name == "Legs" {
                group.addSession(Calendar.current.date(byAdding: .day, value: -9, to: Date())!)
                group.addExercise(name: "Prensa", metric: .strength, icon: "x")
                group.addExercise(name: "Sentadilla", metric: .strength, icon: "x")
            }
            if name == "Piernas" {
                group.addSession(Calendar.current.date(byAdding: .day, value: -2, to: Date())!)
            }
            return group
        }
    }

    @Test(.timeLimit(.minutes(120)))
    func evaluate() async throws {
        guard #available(iOS 27, *) else { return }
        let manifestURL = try #require(bundle.url(forResource: "scaneval_manifest", withExtension: "json"))
        let cases = try JSONDecoder().decode([CaseInfo].self, from: Data(contentsOf: manifestURL))
        print("SCANEVAL_START \(cases.count)")

        for info in cases {
            var out: [String: Any] = ["id": info.id]
            guard let path = bundle.path(forResource: (info.file as NSString).deletingPathExtension, ofType: "jpg"),
                  let image = UIImage(contentsOfFile: path),
                  let cg = await RoutineScanImage.prepare(image) else {
                out["error"] = "no se pudo cargar la imagen"
                try emit(out)
                continue
            }
            out["imageSize"] = "\(cg.width)x\(cg.height)"
            let groups = ownerGroups()
            let start = Date()
            var partials = 0
            var firstPartial: Double?
            do {
                let routine = try await FoundationModelsRoutineScanner().scan(image: cg) { _ in
                    partials += 1
                    if firstPartial == nil { firstPartial = Date().timeIntervalSince(start) }
                }
                out["seconds"] = Date().timeIntervalSince(start)
                out["items"] = routine.items.map(itemJSON)
                let named = routine.items.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let drafts = RoutineImport.drafts(from: routine, groups: groups)
                out["drafts"] = zip(drafts, named).map { draftJSON($0.0, item: $0.1, groups: groups) }
            } catch {
                out["seconds"] = Date().timeIntervalSince(start)
                out["error"] = String(describing: error)
                if case RoutineScanError.failed = error {
                    out["diagnostic"] = await diagnose(cg)
                }
            }
            out["partials"] = partials
            out["firstPartialSeconds"] = firstPartial ?? NSNull()
            try emit(out)
        }
        print("SCANEVAL_END")
    }

    @available(iOS 27, *)
    private func diagnose(_ image: CGImage) async -> String {
        do {
            let session = LanguageModelSession(instructions: "You transcribe workout routines from photos.")
            let response = try await session.respond(generating: ExtractedRoutine.self) {
                "Extract the workout routine from this image."
                Attachment<ImageAttachmentContent>(image)
            }
            return "respond sin streaming OK: \(response.content.exercises.count) ejercicios"
        } catch {
            var text = String(describing: error)
            if let generation = error as? LanguageModelSession.GenerationError {
                text += " || \(generation.localizedDescription) || \(generation.failureReason ?? "-")"
            }
            return text
        }
    }

    private func itemJSON(_ item: ScannedRoutine.Item) -> [String: Any] {
        ["name": item.name, "sets": item.sets ?? NSNull(), "repsText": item.repsText ?? NSNull(),
         "muscle": item.muscle?.rawValue ?? NSNull(), "low": item.lowConfidence]
    }

    private func draftJSON(_ draft: ScannedExerciseDraft, item: ScannedRoutine.Item, groups: [MuscleEntry]) -> [String: Any] {
        var kind = "none"
        var groupName: String?
        switch draft.group {
        case .existing(let id): kind = "existing"; groupName = groups.first { $0.id == id }?.name
        case .new(let name): kind = "new"; groupName = name
        case nil: break
        }
        return ["name": draft.name, "sets": draft.sets ?? NSNull(), "reps": draft.reps ?? NSNull(),
                "repRange": draft.repRange ?? NSNull(), "muscle": item.muscle?.rawValue ?? NSNull(),
                "groupKind": kind, "groupName": groupName ?? NSNull(),
                "groupMuscles": groupName.map { TargetMuscle.muscles(inName: $0).map(\.rawValue).sorted() } ?? [],
                "lowConfidence": draft.lowConfidence, "suggestsSwap": draft.suggestsSwap]
    }

    /// One line per case in the test log, parsed on the Mac.
    private func emit(_ object: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        print("SCANEVAL_RESULT " + String(decoding: data, as: UTF8.self))
    }
}
#endif
