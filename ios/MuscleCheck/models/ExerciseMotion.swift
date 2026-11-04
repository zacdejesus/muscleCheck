//
//  ExerciseMotion.swift
//  MuscleCheck
//
//  Every exercise the app can draw, with the names that mean exactly that movement in
//  ES/EN/FR/IT. The AI coach writes exercises as free text; ExerciseCatalog.motion(for:)
//  matches them against these phrases to pick a pictogram for the suggestion card.
//
//  The rule is strictness: a wrong drawing is worse than none. A phrase belongs here
//  only when it names this movement and not a neighbour, so "press" or "row" with no
//  more context stays undrawn, and more specific variants we don't draw ("sentadilla
//  búlgara", "straight arm pulldown") are listed in ExerciseCatalog without a motion
//  so they win the match and draw nothing. Generic names get one documented answer:
//  "curl" → barbell curl, "extensión de tríceps" → overhead extension, "fondos" →
//  triceps dip, "remo" → barbell row, "elevación de piernas" → hanging leg raise.
//

import Foundation

enum ExerciseMotion: String, CaseIterable, Sendable {
    // Chest
    case benchPress, inclineDumbbellPress, pushUp, declineBenchPress, chestDip
    // Back
    case pullUp, latPulldown, barbellRow, oneArmDumbbellRow, seatedCableRow, deadlift, pullover
    // Legs
    case squat, legPress, romanianDeadlift, lunge, legExtension, legCurl, calfRaise
    // Shoulders
    case militaryPress, seatedDumbbellPress, frontRaise, pikePushUp, landminePress
    // Biceps
    case barbellCurl, dumbbellCurl, hammerCurl, preacherCurl, cableCurl, concentrationCurl, inclineCurl
    // Triceps
    case cablePushdown, tricepsDip, skullCrusher, overheadTricepsExtension, closeGripBenchPress
    case tricepsKickback, benchDip
    // Core
    case crunch, plank, hangingLegRaise, abWheel

    /// The muscle the movement is filed under. It must agree with ExerciseCatalog's
    /// documented answers, since these phrases also feed the routine scan.
    var muscle: TargetMuscle {
        switch self {
        case .benchPress, .inclineDumbbellPress, .pushUp, .declineBenchPress, .chestDip: .chest
        case .pullUp, .latPulldown, .barbellRow, .oneArmDumbbellRow, .seatedCableRow, .deadlift, .pullover: .back
        case .squat, .legPress, .romanianDeadlift, .lunge, .legExtension, .legCurl: .legs
        case .calfRaise: .calves
        case .militaryPress, .seatedDumbbellPress, .frontRaise, .pikePushUp, .landminePress: .shoulders
        case .barbellCurl, .dumbbellCurl, .hammerCurl, .preacherCurl, .cableCurl, .concentrationCurl,
             .inclineCurl: .biceps
        case .cablePushdown, .tricepsDip, .skullCrusher, .overheadTricepsExtension, .closeGripBenchPress,
             .tricepsKickback, .benchDip: .triceps
        case .crunch, .plank, .hangingLegRaise, .abWheel: .core
        }
    }

    var pictogram: ExercisePictogram {
        switch self {
        case .benchPress: .benchPress
        case .inclineDumbbellPress: .inclineDumbbellPress
        case .pushUp: .pushUp
        case .declineBenchPress: .declineBenchPress
        case .chestDip: .chestDip
        case .pullUp: .pullUp
        case .latPulldown: .latPulldown
        case .barbellRow: .barbellRow
        case .oneArmDumbbellRow: .oneArmDumbbellRow
        case .seatedCableRow: .seatedCableRow
        case .deadlift: .deadlift
        case .pullover: .pullover
        case .squat: .squat
        case .legPress: .legPress
        case .romanianDeadlift: .romanianDeadlift
        case .lunge: .lunge
        case .legExtension: .legExtension
        case .legCurl: .legCurl
        case .calfRaise: .calfRaise
        case .militaryPress: .militaryPress
        case .seatedDumbbellPress: .seatedDumbbellPress
        case .frontRaise: .frontRaise
        case .pikePushUp: .pikePushUp
        case .landminePress: .landminePress
        case .barbellCurl: .barbellCurl
        case .dumbbellCurl: .dumbbellCurl
        case .hammerCurl: .hammerCurl
        case .preacherCurl: .preacherCurl
        case .cableCurl: .cableCurl
        case .concentrationCurl: .concentrationCurl
        case .inclineCurl: .inclineCurl
        case .cablePushdown: .cablePushdown
        case .tricepsDip: .tricepsDip
        case .skullCrusher: .skullCrusher
        case .overheadTricepsExtension: .overheadTricepsExtension
        case .closeGripBenchPress: .closeGripBenchPress
        case .tricepsKickback: .tricepsKickback
        case .benchDip: .benchDip
        case .crunch: .crunch
        case .plank: .plank
        case .hangingLegRaise: .hangingLegRaise
        case .abWheel: .abWheel
        }
    }

    /// Names for this exact movement. Matched as whole words on folded text (case,
    /// accents and punctuation ignored), so "Push-ups con peso" finds "push ups" and
    /// plurals need their own entry.
    var phrases: [String] {
        switch self {
        case .benchPress: [
            "press de banca", "press banca", "press plano", "press de pecho", "press pecho", "bench press",
            "flat bench press", "chest press", "développé couché", "panca piana",
        ]
        case .inclineDumbbellPress: [
            "press inclinado", "incline press", "incline dumbbell press", "incline bench press",
            "développé incliné", "panca inclinata",
        ]
        case .pushUp: [
            "flexiones", "flexiones de brazos", "lagartijas", "push up", "push ups", "pushups",
            "pompes", "piegamenti", "piegamenti sulle braccia",
        ]
        case .declineBenchPress: [
            "press declinado", "decline press", "decline bench press", "développé décliné", "décliné couché",
            "panca declinata",
        ]
        case .chestDip: [
            "fondos para pecho", "fondos de pecho", "chest dip", "chest dips", "dips pectoraux",
            "dip per il petto",
        ]
        case .pullUp: [
            "dominadas", "dominada", "pull up", "pull ups", "pullups", "chin up", "chin ups", "tractions",
            "traction", "trazioni", "trazioni alla sbarra",
        ]
        case .latPulldown: [
            "jalón al pecho", "jalón", "jalones", "lat pulldown", "pulldown", "pull down", "tirage vertical",
            "tirage poitrine", "lat machine",
        ]
        case .barbellRow: [
            "remo", "remos", "remo con barra", "barbell row", "bent over row", "rowing barre", "rowing",
            "rematore", "rematore con bilanciere", "rematore con barra",
        ]
        case .oneArmDumbbellRow: [
            "remo con mancuerna", "remo a una mano", "one arm row", "one arm dumbbell row", "dumbbell row",
            "rowing haltère", "rematore con manubrio",
        ]
        case .seatedCableRow: [
            "remo en polea", "remo sentado", "remo en polea baja", "seated cable row", "seated row",
            "cable row", "tirage horizontal", "pulley basso",
        ]
        case .deadlift: ["peso muerto", "deadlift", "soulevé de terre", "stacco", "stacco da terra"]
        case .pullover: ["pullover", "pull over"]
        case .squat: [
            "sentadilla", "sentadillas", "sentadilla con barra", "sentadilla frontal", "squat", "squats",
            "back squat", "front squat", "squat con bilanciere",
        ]
        case .legPress: [
            "prensa", "prensa inclinada", "press de piernas", "leg press", "presse à cuisses", "pressa",
        ]
        case .romanianDeadlift: [
            "peso muerto rumano", "romanian deadlift", "rdl", "soulevé de terre roumain", "stacco rumeno",
        ]
        case .lunge: [
            "zancadas", "zancada", "estocadas", "estocada", "desplantes", "lunges", "lunge", "fentes",
            "affondi",
        ]
        case .legExtension: [
            "extensión de cuádriceps", "extensiones de cuádriceps", "extensión de piernas", "leg extension",
            "leg extensions",
        ]
        case .legCurl: [
            "curl femoral", "curl femorales", "curl de piernas", "leg curl", "lying leg curl",
        ]
        case .calfRaise: [
            "elevación de talones", "elevaciones de talones", "gemelos", "gemelos de pie", "calf raise",
            "calf raises", "mollets", "polpacci",
        ]
        case .militaryPress: [
            "press militar", "military press", "overhead press", "ohp", "développé militaire", "lento avanti",
        ]
        case .seatedDumbbellPress: [
            "press de hombros", "press de hombro", "press hombros", "shoulder press", "dumbbell shoulder press",
            "développé épaules", "military press con manubri",
        ]
        case .frontRaise: [
            "elevaciones frontales", "elevación frontal", "front raise", "front raises",
            "élévations frontales", "élévation frontale", "alzate frontali",
        ]
        case .pikePushUp: ["pike push up", "pike push ups", "flexiones pica", "flexiones en pica"]
        case .landminePress: ["landmine press", "press landmine"]
        case .barbellCurl: [
            "curl", "curls", "curl de bíceps", "curl bíceps", "curl con barra", "bicep curl", "biceps curl",
            "barbell curl", "curl barre", "curl bilanciere", "curl con bilanciere", "curl con barra dritta",
        ]
        case .dumbbellCurl: [
            "curl con mancuernas", "curl con mancuerna", "curl alternado", "dumbbell curl", "curl haltères",
            "curl manubri", "curl con manubrio", "curl con manubri",
        ]
        case .hammerCurl: [
            "curl martillo", "hammer curl", "hammer curls", "curl marteau", "curl prise neutre", "curl a martello",
        ]
        case .preacherCurl: [
            "curl predicador", "curl scott", "preacher curl", "preacher curls", "curl pupitre",
        ]
        case .cableCurl: ["curl en polea", "curl con polea", "cable curl", "curl à la poulie", "curl ai cavi"]
        case .concentrationCurl: [
            "curl concentrado", "concentration curl", "concentration curls", "curl concentré", "curl concentrato",
        ]
        case .inclineCurl: [
            "curl inclinado", "incline curl", "incline dumbbell curl", "curl incliné",
        ]
        case .cablePushdown: [
            "tríceps polea", "tríceps en polea", "jalón de tríceps", "tríceps con cuerda",
            "extensión de tríceps con cuerda", "extensión de tríceps en polea", "pushdown",
            "push down", "tricep pushdown", "triceps pushdown", "triceps à la poulie", "tricipiti alla corda",
            "tricipiti al cavo",
        ]
        case .tricepsDip: [
            "fondos", "fondos en paralelas", "dips", "dip", "triceps dips", "dip sur barre",
            "dip alle parallele",
        ]
        case .skullCrusher: [
            "press francés", "rompecráneos", "skull crusher", "skullcrusher", "skull crush", "barra francese",
            "french press", "extensión de tríceps con barra", "extensiones de tríceps con barra",
        ]
        case .overheadTricepsExtension: [
            "extensión de tríceps", "extensión tríceps", "extensiones de tríceps", "triceps extension",
            "tricep extension", "overhead triceps extension", "overhead extension", "extension triceps",
            "extension des triceps", "extensions triceps", "extensions de triceps", "estensioni tricipiti",
            "estensione tricipiti", "french press con manubrio",
        ]
        case .closeGripBenchPress: [
            "press cerrado", "press de banca agarre cerrado", "close grip bench press", "close grip bench",
            "développé couché prise serrée", "panca presa stretta",
        ]
        case .tricepsKickback: ["patada de tríceps", "kickback", "triceps kickback", "kickback triceps"]
        case .benchDip: ["fondos en banco", "bench dips", "bench dip", "dips sur banc", "dip su panca"]
        case .crunch: [
            "crunch", "crunches", "crunchs", "encogimientos abdominales", "ab crunch", "crunch addominali",
        ]
        case .plank: ["plancha", "planchas", "plank", "gainage", "planche"]
        case .hangingLegRaise: [
            "elevación de piernas", "elevaciones de piernas", "elevación de pierna", "leg raise", "leg raises",
            "hanging leg raise", "relevés de jambes", "levés de jambes", "sollevamento gambe",
        ]
        case .abWheel: ["rueda abdominal", "ab wheel", "ab wheel rollout", "roue abdominale", "ruota addominale"]
        }
    }
}
