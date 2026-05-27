//
//  PromptExperiment.swift
//  MuscleCheck
//
//  TEMPORARY harness to tune Feature 12 coach instructions/prompt against the
//  real on-device model. Only does work on iOS 26 + Apple Intelligence (device).
//  Run explicitly: -only-testing:MuscleCheckTests/PromptExperiment
//  Delete once the prompt is settled.
//

import Testing
import FoundationModels
@testable import MuscleCheck
import Foundation

struct PromptExperiment {

    struct Case { let name: String; let instructions: String; let prompt: String; let names: [String] }

    private func groupName(_ names: [String], _ i: Int) -> String {
        names.indices.contains(i) ? names[i] : "?(\(i))"
    }

    @Test
    func runMatrix() async throws {
        guard #available(iOS 26, *) else { print("⚠️ Necesita iOS 26 — saltando."); return }
        guard case .available = SystemLanguageModel.default.availability else {
            print("⚠️ MODEL UNAVAILABLE"); return
        }

        // Winning instruction (Round 4), per language.
        let instrES = "Sos un entrenador de gimnasio. De la lista de grupos DISPONIBLES, elegí EXACTAMENTE 2 que formen un día coherente que se entrene junto (empuje: pecho/hombros/tríceps; tirón: espalda/bíceps; piernas: piernas/abdomen). Elegí por índice. Para CADA grupo dá 3 ejercicios que trabajen ESPECÍFICAMENTE ese músculo; nunca pongas ejercicios de otro grupo. Respondé en español."
        let instrEN = "You are a gym trainer. From the list of AVAILABLE groups, pick EXACTLY 2 that form a coherent day trained together (push: chest/shoulders/triceps; pull: back/biceps; legs: legs/abs). Pick by index. For EACH group give 3 exercises that work SPECIFICALLY that muscle; never put exercises from another group. Respond in English."
        let instrFR = "Tu es un coach de gym. Dans la liste des groupes DISPONIBLES, choisis EXACTEMENT 2 qui forment une journée cohérente entraînée ensemble (poussée : pectoraux/épaules/triceps ; tirage : dos/biceps ; jambes : jambes/abdos). Choisis par index. Pour CHAQUE groupe donne 3 exercices qui travaillent SPÉCIFIQUEMENT ce muscle ; ne mets jamais d'exercices d'un autre groupe. Réponds en français."

        func promptES(_ l: String) -> String { "Grupos DISPONIBLES para hoy (elegí por índice): \(l)\n\n¿Qué día de entrenamiento (2 grupos coherentes + 3 ejercicios cada uno) me recomendás?" }
        func promptEN(_ l: String) -> String { "AVAILABLE groups for today (pick by index): \(l)\n\nWhich training day (2 coherent groups + 3 exercises each) do you recommend?" }
        func promptFR(_ l: String) -> String { "Groupes DISPONIBLES aujourd'hui (choisis par index) : \(l)\n\nQuelle journée d'entraînement (2 groupes cohérents + 3 exercices chacun) recommandes-tu ?" }

        let esNames = ["Pecho", "Espalda", "Piernas", "Hombros", "Bíceps", "Tríceps", "Abdomen"]
        let enNames = ["Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Abs"]
        let frNames = ["Pectoraux", "Dos", "Jambes", "Épaules", "Biceps", "Triceps", "Abdos"]
        func numbered(_ n: [String]) -> String { n.enumerated().map { "\($0.offset)=\($0.element)" }.joined(separator: ", ") }

        // Novel / unusual / custom groups (ES).
        let novelA = ["Trapecios", "Antebrazos", "Gemelos", "Glúteos", "Lumbares", "Pecho", "Espalda"]
        let novelB = ["Brazos", "Core", "Tren superior", "Tren inferior", "Hombros"]

        let cases = [
            Case(name: "IDIOMA ES", instructions: instrES, prompt: promptES(numbered(esNames)), names: esNames),
            Case(name: "IDIOMA EN", instructions: instrEN, prompt: promptEN(numbered(enNames)), names: enNames),
            Case(name: "IDIOMA FR", instructions: instrFR, prompt: promptFR(numbered(frNames)), names: frNames),
            Case(name: "NUEVOS-A (trapecios/antebrazos/gemelos/glúteos/lumbares/pecho/espalda)",
                 instructions: instrES, prompt: promptES(numbered(novelA)), names: novelA),
            Case(name: "NUEVOS-B (custom vagos: brazos/core/tren sup/tren inf/hombros)",
                 instructions: instrES, prompt: promptES(numbered(novelB)), names: novelB),
        ]

        var opts = GenerationOptions()
        opts.temperature = 0.7
        opts.maximumResponseTokens = 512

        _ = try? await LanguageModelSession(instructions: Instructions { "Sos un asistente." })
            .respond(to: "Decí 'listo'.", options: opts)

        for c in cases {
            print("\n###### \(c.name) ######")
            for run in 1...2 {
                let session = LanguageModelSession(instructions: Instructions { c.instructions })
                do {
                    let r = try await session.respond(to: c.prompt, generating: WorkoutSuggestion.self, options: opts).content
                    let g = r.blocks.map { groupName(c.names, $0.groupIndex) }.joined(separator: "+")
                    print("→ run\(run): [\(r.focus)] \(g)")
                    for b in r.blocks {
                        print("     \(groupName(c.names, b.groupIndex)): \(b.exercises.joined(separator: ", "))")
                    }
                } catch {
                    print("→ run\(run): ❌ \(error)")
                }
            }
        }
        print("\n###### FIN ######")
    }
}
