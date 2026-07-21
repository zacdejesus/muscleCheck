//
//  LocalizedInstructions.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 24/10/2025.
//
//  Localized instructions/prompt for the AI Coach (Feature 12). The instruction is
//  the tuned, on-device winner from docs/feature12-prompt-tuning.md: it does NOT ask
//  the model to rotate or reason over history (that lives in WorkoutEligibility) — it
//  only asks for a coherent pair + group-specific exercises.
//

import FoundationModels
import Foundation

struct LocalizedStrings {

    /// Language the app UI is actually displaying (its active Bundle localization), so the
    /// AI answers in the SAME language the user sees. We must not use
    /// `Locale.current.language`, which follows the device region / preferred-language
    /// order and can diverge from the UI localization (e.g. a per-app language override) —
    /// that mismatch produced an English UI with Spanish AI output.
    /// Internal (not private): MuscleCheckAI compares it against the model's
    /// supported languages to detect the Siri-language mismatch.
    static var appLanguage: String? {
        Bundle.main.preferredLocalizations.first.map { String($0.prefix(2)) }
    }

    /// Coach persona + rules for the day-suggestion feature.
    @available(iOS 26, *)
    static var coachInstructions: Instructions {
        let lang = appLanguage
        switch lang {
        case "es":
            return Instructions {
                "Sos un entrenador de gimnasio."
                "De la lista de grupos DISPONIBLES, elegí EXACTAMENTE 2 que formen un día coherente que se entrene junto (empuje: pecho/hombros/tríceps; tirón: espalda/bíceps; piernas: piernas/abdomen)."
                "Elegí por índice."
                "Para CADA grupo dá 3 ejercicios que trabajen ESPECÍFICAMENTE ese músculo; nunca pongas ejercicios de otro grupo (ej: no pongas sentadillas en bíceps, ni curls en tríceps)."
                "Respondé en español."
            }
        case "fr":
            return Instructions {
                "Tu es un coach de gym."
                "Dans la liste des groupes DISPONIBLES, choisis EXACTEMENT 2 qui forment une journée cohérente entraînée ensemble (poussée : pectoraux/épaules/triceps ; tirage : dos/biceps ; jambes : jambes/abdos)."
                "Choisis par index."
                "Pour CHAQUE groupe, donne 3 exercices qui ciblent SPÉCIFIQUEMENT ce muscle ; ne mets jamais d'exercices d'un autre groupe (ex : pas de squats pour les biceps, ni de curls pour les triceps)."
                "Réponds en français."
            }
        case "it":
            return Instructions {
                "Sei un coach di palestra."
                "Dalla lista dei gruppi DISPONIBILI, scegli ESATTAMENTE 2 che formino una giornata coerente da allenare insieme (spinta: petto/spalle/tricipiti; trazione: schiena/bicipiti; gambe: gambe/addome)."
                "Scegli per indice."
                "Per OGNI gruppo dai 3 esercizi che lavorino SPECIFICAMENTE quel muscolo; non mettere mai esercizi di un altro gruppo (es: niente squat nei bicipiti, né curl nei tricipiti)."
                "Rispondi in italiano."
            }
        default:
            return Instructions {
                "You are a gym coach."
                "From the list of AVAILABLE groups, pick EXACTLY 2 that make a coherent day trained together (push: chest/shoulders/triceps; pull: back/biceps; legs: legs/abs)."
                "Pick by index."
                "For EACH group give 3 exercises that work SPECIFICALLY that muscle; never put exercises from another group (e.g. no squats under biceps, no curls under triceps)."
                "Answer in English."
            }
        }
    }

    /// Per-call prompt: just the user's numbered, already-eligible gym groups.
    /// No history — rotation is resolved in code, so the model doesn't need it.
    /// The language directive is repeated here (last position — the strongest spot
    /// for the small on-device model) as insurance against the English-described
    /// @Generable schema pulling the output toward English.
    static func coachPrompt(groups: String) -> String {
        let lang = appLanguage
        switch lang {
        case "es":
            return """
            Grupos disponibles (elegí por índice): \(groups)

            ¿Qué día de entrenamiento (exactamente 2 grupos coherentes + 3 ejercicios cada uno) me recomendás para hoy? Escribí TODO en español: focus, ejercicios y justificación.
            """
        case "fr":
            return """
            Groupes disponibles (choisis par index) : \(groups)

            Quelle journée d'entraînement (exactement 2 groupes cohérents + 3 exercices chacun) me recommandes-tu pour aujourd'hui ? Écris TOUT en français : focus, exercices et justification.
            """
        case "it":
            return """
            Gruppi disponibili (scegli per indice): \(groups)

            Quale giornata di allenamento (esattamente 2 gruppi coerenti + 3 esercizi ciascuno) mi consigli per oggi? Scrivi TUTTO in italiano: focus, esercizi e motivazione.
            """
        default:
            return """
            Available groups (pick by index): \(groups)

            What training day (exactly 2 coherent groups + 3 exercises each) do you recommend for today? Write EVERYTHING in English: focus, exercises and rationale.
            """
        }
    }

    /// Warmup prompt prefix to reduce cold-start latency on first real call.
    @available(iOS 26, *)
    static var promtPrefix: Prompt {
        let lang = appLanguage
        switch lang {
        case "es":
            return Prompt("Grupos disponibles (elegí por índice): 0=Espalda, 1=Bíceps, 2=Pecho, 3=Tríceps")
        case "fr":
            return Prompt("Groupes disponibles (choisis par index) : 0=Dos, 1=Biceps, 2=Pectoraux, 3=Triceps")
        case "it":
            return Prompt("Gruppi disponibili (scegli per indice): 0=Schiena, 1=Bicipiti, 2=Petto, 3=Tricipiti")
        default:
            return Prompt("Available groups (pick by index): 0=Back, 1=Biceps, 2=Chest, 3=Triceps")
        }
    }
}
