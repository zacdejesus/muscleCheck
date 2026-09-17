//
//  ExerciseCatalog.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  Common exercises → the muscle they train (ES/EN/FR/IT). The on-device model names muscles by
//  how a word SOUNDS: in the iPhone evaluation "Prensa" (leg press) came back as chest five
//  times, "Jalón al pecho" as chest, "Aperturas" as shoulders. For every exercise this table
//  knows, the code decides instead of the model.
//
//  Ambiguous exercises get one documented answer: peso muerto → espalda (rumano → piernas),
//  fondos → tríceps, encogimientos → hombros, face pull → hombros, sentadilla sumo → piernas.
//

import Foundation

enum ExerciseCatalog {

    enum Lookup: Equatable {
        /// A known exercise. A `nil` muscle means cardio or full body: no gym group fits.
        case known(TargetMuscle?)
        case unknown
    }

    /// Whole-word match on folded text (case, accents and punctuation ignored); the most specific
    /// phrase wins ("press de piernas" before "press militar" before "curl").
    static func lookup(_ exercise: String) -> Lookup {
        let folded = NameMatching.fold(exercise)
        guard !folded.isEmpty else { return .unknown }
        let padded = " \(folded) "
        for entry in sortedEntries where padded.contains(" \(entry.phrase) ") {
            return .known(entry.muscle)
        }
        return .unknown
    }

    private typealias Entry = (phrase: String, muscle: TargetMuscle?)

    /// More words first, then longer phrases, so "curl femoral" is tried before "curl".
    private static let sortedEntries: [Entry] = entries.sorted {
        let lhsWords = $0.phrase.split(separator: " ").count, rhsWords = $1.phrase.split(separator: " ").count
        return lhsWords != rhsWords ? lhsWords > rhsWords : $0.phrase.count > $1.phrase.count
    }

    private static func group(_ muscle: TargetMuscle?, _ names: [String]) -> [Entry] {
        names.map { (NameMatching.fold($0), muscle) }
    }

    private static let entries: [Entry] =
        group(.chest, [
            "press banca", "press de banca", "press plano", "press inclinado", "press declinado", "press de pecho",
            "press pecho", "chest press", "bench press", "bench", "incline press", "incline", "decline press",
            "aperturas", "apertura", "cruce de poleas", "cruces de polea", "crossover", "pec deck", "peck deck",
            "contractora", "flexiones", "flexiones de brazos", "lagartijas", "push ups", "push up", "pushups",
            "flyes", "fly", "flys", "chest fly", "développé couché", "développé incliné", "pompes", "écarté",
            "écartés", "panca piana", "panca inclinata", "panca", "croci", "piegamenti",
        ])
        + group(.back, [
            "dominadas", "dominada", "pull ups", "pull up", "pullups", "chin ups", "chin up", "jalón", "jalones",
            "jalón al pecho", "jalón tras nuca", "lat pulldown", "pulldown", "remo", "remos", "remo con barra",
            "remo con mancuerna", "row", "rows", "barbell row", "seated row", "peso muerto", "deadlift",
            "hiperextensiones", "hiperextensión", "extensión lumbar", "pullover", "tractions", "traction",
            "tirage", "rowing", "soulevé de terre", "lat machine", "rematore", "trazioni", "stacco",
            "stacco da terra", "pulley",
        ])
        + group(.shoulders, [
            "press militar", "press de hombros", "press de hombro", "press hombros", "press arnold", "arnold",
            "military press", "overhead press", "shoulder press", "ohp", "elevaciones laterales",
            "elevación lateral", "elevaciones frontales", "elevación frontal", "vuelos laterales", "laterales",
            "pájaros", "pájaro", "posteriores", "face pull", "encogimientos", "encogimiento", "shrugs", "shrug",
            "lateral raises", "lateral raise", "front raises", "front raise", "rear delt", "remo al cuello",
            "upright row", "développé militaire", "élévations latérales", "alzate laterali", "lento avanti",
        ])
        + group(.biceps, [
            "curl", "curls", "curl de bíceps", "curl bíceps", "curl con barra", "curl martillo", "hammer curl",
            "curl concentrado", "curl predicador", "curl scott", "bicep curl", "biceps curl", "incline curl",
            "curl bilanciere", "curl manubri", "curl alternado",
        ])
        + group(.triceps, [
            "extensión de tríceps", "extensión tríceps", "extensiones de tríceps", "tríceps polea",
            "tríceps en polea", "jalón de tríceps", "pushdown", "tricep pushdown", "triceps pushdown",
            "press francés", "french press", "skull crusher", "skullcrusher", "rompecráneos",
            "patada de tríceps", "kickback", "fondos", "fondos en paralelas", "dips", "bench dips",
            "press cerrado", "close grip bench press", "estensioni tricipiti", "barra francese",
        ])
        + group(.legs, [
            "sentadilla", "sentadillas", "squat", "squats", "sentadilla búlgara", "búlgaras", "bulgares",
            "split squat", "prensa", "prensa inclinada", "press de piernas", "leg press", "presse",
            "presse à cuisses", "extensión de cuádriceps", "extensiones de cuádriceps", "extensión cuádriceps",
            "extensión de piernas", "leg extension", "leg extensions", "cuádriceps", "curl femoral",
            "curl de piernas", "curl femorales", "leg curl", "femoral", "isquiotibiales", "zancadas", "zancada",
            "estocadas", "estocada", "lunges", "lunge", "desplantes", "fentes", "affondi", "step up", "step ups",
            "peso muerto rumano", "romanian deadlift", "rdl", "hack squat", "sentadilla hack", "goblet squat",
            "sissy squat", "pistol squat",
        ])
        + group(.glutes, [
            "hip thrust", "hip thrusts", "puente de glúteo", "puente de glúteos", "puente glúteo",
            "glute bridge", "patada de glúteo", "patada glúteo", "patadas de glúteo", "patada", "patadas",
            "kickback de glúteo", "glute kickback", "abducción", "abducciones", "abductores", "abductor",
            "hip abduction", "clamshell",
        ])
        + group(.calves, [
            "gemelos", "gemelo", "gemelos de pie", "pantorrillas", "pantorrilla", "elevación de talones",
            "elevaciones de talones", "talones", "calf raise", "calf raises", "calf", "calves", "mollets",
            "polpacci", "sóleo",
        ])
        + group(.core, [
            "plancha", "planchas", "plank", "crunch", "crunches", "abdominales", "abdominal",
            "encogimientos abdominales", "elevación de piernas", "elevaciones de piernas", "leg raise",
            "leg raises", "russian twist", "rueda abdominal", "ab wheel", "mountain climbers", "mountain climber",
            "escaladores", "hollow", "dead bug", "sit ups", "sit up", "oblicuos", "gainage", "crunch addominali",
            "plank laterale", "bicicleta abdominal",
        ])
        + group(.forearms, [
            "curl de muñeca", "curl muñeca", "wrist curl", "wrist curls", "antebrazo", "antebrazos",
        ])
        + group(nil, [
            "cinta", "caminadora", "trotadora", "bici", "bicicleta", "spinning", "elíptica", "correr", "running",
            "trote", "caminata", "remo ergómetro", "remoergómetro", "soga", "saltar la soga", "salto de soga",
            "burpees", "burpee", "jumping jacks", "saltos", "saltos al cajón", "box jumps", "cardio", "hiit",
            "tapis roulant", "cyclette",
        ])
}
