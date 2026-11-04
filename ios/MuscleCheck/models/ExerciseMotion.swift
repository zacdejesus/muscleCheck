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
//  triceps dip, "remo" → barbell row, "elevación de piernas" → hanging leg raise,
//  "aperturas"/"flyes" → dumbbell fly, "abducción" → standing hip abduction, Arnold
//  press → seated dumbbell press.
//

import CoreGraphics
import Foundation

enum ExerciseMotion: String, CaseIterable, Sendable {
    // Chest
    case benchPress, inclineDumbbellPress, pushUp, declineBenchPress, chestDip
    case dumbbellFly, cableCrossover, pecDeck
    // Back
    case pullUp, latPulldown, barbellRow, oneArmDumbbellRow, seatedCableRow, deadlift, pullover
    case straightArmPulldown, backExtension
    // Legs
    case squat, legPress, romanianDeadlift, lunge, legExtension, legCurl, calfRaise
    case bulgarianSplitSquat, gobletSquat, stepUp
    // Glutes
    case hipThrust, gluteBridge, hipAbduction
    // Shoulders
    case militaryPress, seatedDumbbellPress, frontRaise, pikePushUp, landminePress
    case lateralRaise, rearDeltFly, shrug, uprightRow, facePull
    // Biceps
    case barbellCurl, dumbbellCurl, hammerCurl, preacherCurl, cableCurl, concentrationCurl, inclineCurl
    // Triceps
    case cablePushdown, tricepsDip, skullCrusher, overheadTricepsExtension, closeGripBenchPress
    case tricepsKickback, benchDip
    // Core
    case crunch, plank, hangingLegRaise, abWheel, sitUp, mountainClimber

    /// The muscle the movement is filed under. It must agree with ExerciseCatalog's
    /// documented answers, since these phrases also feed the routine scan.
    var muscle: TargetMuscle {
        switch self {
        case .benchPress, .inclineDumbbellPress, .pushUp, .declineBenchPress, .chestDip, .dumbbellFly,
             .cableCrossover, .pecDeck: .chest
        case .pullUp, .latPulldown, .barbellRow, .oneArmDumbbellRow, .seatedCableRow, .deadlift, .pullover,
             .straightArmPulldown, .backExtension: .back
        case .squat, .legPress, .romanianDeadlift, .lunge, .legExtension, .legCurl, .bulgarianSplitSquat,
             .gobletSquat, .stepUp: .legs
        case .hipThrust, .gluteBridge, .hipAbduction: .glutes
        case .calfRaise: .calves
        case .militaryPress, .seatedDumbbellPress, .frontRaise, .pikePushUp, .landminePress, .lateralRaise,
             .rearDeltFly, .shrug, .uprightRow, .facePull: .shoulders
        case .barbellCurl, .dumbbellCurl, .hammerCurl, .preacherCurl, .cableCurl, .concentrationCurl,
             .inclineCurl: .biceps
        case .cablePushdown, .tricepsDip, .skullCrusher, .overheadTricepsExtension, .closeGripBenchPress,
             .tricepsKickback, .benchDip: .triceps
        case .crunch, .plank, .hangingLegRaise, .abWheel, .sitUp, .mountainClimber: .core
        }
    }

    /// The drawing: a side view, or the front view for movements that open sideways.
    var drawing: PictogramDrawing {
        switch self {
        case .benchPress: .side(.benchPress)
        case .inclineDumbbellPress: .side(.inclineDumbbellPress)
        case .pushUp: .side(.pushUp)
        case .declineBenchPress: .side(.declineBenchPress)
        case .chestDip: .side(.chestDip)
        case .pullUp: .side(.pullUp)
        case .latPulldown: .side(.latPulldown)
        case .barbellRow: .side(.barbellRow)
        case .oneArmDumbbellRow: .side(.oneArmDumbbellRow)
        case .seatedCableRow: .side(.seatedCableRow)
        case .deadlift: .side(.deadlift)
        case .pullover: .side(.pullover)
        case .squat: .side(.squat)
        case .legPress: .side(.legPress)
        case .romanianDeadlift: .side(.romanianDeadlift)
        case .lunge: .side(.lunge)
        case .legExtension: .side(.legExtension)
        case .legCurl: .side(.legCurl)
        case .calfRaise: .side(.calfRaise)
        case .militaryPress: .side(.militaryPress)
        case .seatedDumbbellPress: .side(.seatedDumbbellPress)
        case .frontRaise: .side(.frontRaise)
        case .pikePushUp: .side(.pikePushUp)
        case .landminePress: .side(.landminePress)
        case .barbellCurl: .side(.barbellCurl)
        case .dumbbellCurl: .side(.dumbbellCurl)
        case .hammerCurl: .side(.hammerCurl)
        case .preacherCurl: .side(.preacherCurl)
        case .cableCurl: .side(.cableCurl)
        case .concentrationCurl: .side(.concentrationCurl)
        case .inclineCurl: .side(.inclineCurl)
        case .cablePushdown: .side(.cablePushdown)
        case .tricepsDip: .side(.tricepsDip)
        case .skullCrusher: .side(.skullCrusher)
        case .overheadTricepsExtension: .side(.overheadTricepsExtension)
        case .closeGripBenchPress: .side(.closeGripBenchPress)
        case .tricepsKickback: .side(.tricepsKickback)
        case .benchDip: .side(.benchDip)
        case .crunch: .side(.crunch)
        case .plank: .side(.plank)
        case .hangingLegRaise: .side(.hangingLegRaise)
        case .abWheel: .side(.abWheel)
        case .straightArmPulldown: .side(.straightArmPulldown)
        case .backExtension: .side(.backExtension)
        case .bulgarianSplitSquat: .side(.bulgarianSplitSquat)
        case .gobletSquat: .side(.gobletSquat)
        case .stepUp: .side(.stepUp)
        case .hipThrust: .side(.hipThrust)
        case .gluteBridge: .side(.gluteBridge)
        case .facePull: .side(.facePull)
        case .sitUp: .side(.sitUp)
        case .mountainClimber: .side(.mountainClimber)
        case .cableCrossover: .front(.cableCrossover)
        case .dumbbellFly: .front(.dumbbellFly)
        case .hipAbduction: .front(.hipAbduction)
        case .lateralRaise: .front(.lateralRaise)
        case .pecDeck: .front(.pecDeck)
        case .rearDeltFly: .front(.rearDeltFly)
        case .shrug: .front(.shrug)
        case .uprightRow: .front(.uprightRow)
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
            "développé épaules", "military press con manubri", "press arnold", "arnold press", "arnold",
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
        case .dumbbellFly: [
            "aperturas", "apertura", "aperturas con mancuernas", "aperturas planas", "aperturas en banco", "flyes",
            "fly", "flys", "flies", "chest fly", "chest flyes", "chest flies", "dumbbell fly", "dumbbell flyes",
            "dumbbell flies", "écarté", "écartés", "écarté couché", "écartés couché", "écartés avec haltères", "croci",
            "croci con manubri", "croci su panca",
        ]
        case .cableCrossover: [
            "cruce de poleas", "cruce de polea", "cruces de polea", "cruces de poleas", "cruces en polea",
            "cruces en poleas", "aperturas en polea", "crossover", "cable crossover", "cable fly", "cable flyes",
            "cable flies", "écarté à la poulie", "écartés à la poulie", "vis à vis poulie", "croci ai cavi",
            "croci al cavo", "crossover ai cavi",
        ]
        case .pecDeck: [
            "pec deck", "peck deck", "contractora", "máquina de aperturas", "aperturas en máquina", "butterfly",
            "machine fly", "pec fly", "papillon", "pectoral machine", "croci alla macchina",
        ]
        case .straightArmPulldown: [
            "straight arm pulldown", "straight arm pulldowns", "straight arm lat pulldown", "jalón con brazos rectos",
            "jalón con brazos estirados", "pullover en polea", "pull over en polea", "tirage bras tendus",
            "pull over à la poulie", "pulldown a braccia tese",
        ]
        case .backExtension: [
            "hiperextensiones", "hiperextensión", "extensión lumbar", "extensiones lumbares", "back extension",
            "back extensions", "hyperextension", "hyperextensions", "extension du dos", "extensions lombaires",
            "iperestensioni",
        ]
        case .bulgarianSplitSquat: [
            "sentadilla búlgara", "sentadillas búlgaras", "búlgaras", "búlgara", "bulgarian split squat",
            "bulgarian split squats", "split squat", "split squats", "fentes bulgares", "bulgares", "squat bulgare",
            "affondi bulgari", "squat bulgaro",
        ]
        case .gobletSquat: [
            "goblet squat", "goblet squats", "sentadilla goblet", "sentadillas goblet", "sentadilla copa", "squat goblet",
            "squat gobelet",
        ]
        case .stepUp: [
            "step up", "step ups", "stepups", "subidas al cajón", "subida al cajón", "subidas al banco",
            "montées sur banc", "montée sur banc", "step up su panca",
        ]
        case .hipThrust: [
            "hip thrust", "hip thrusts", "empuje de cadera", "empujes de cadera", "hip thrust con barra",
        ]
        case .gluteBridge: [
            "puente de glúteo", "puente de glúteos", "puente glúteo", "glute bridge", "glute bridges", "pont fessier",
            "ponte glutei", "ponte per glutei",
        ]
        case .hipAbduction: [
            "abducción de cadera", "abducciones de cadera", "abducción", "abducciones", "abductores", "abductor",
            "hip abduction", "hip abductions", "abduction de hanche", "abductions", "abduttori", "abduzione",
        ]
        case .lateralRaise: [
            "elevaciones laterales", "elevación lateral", "vuelos laterales", "laterales", "lateral raise",
            "lateral raises", "side raise", "side raises", "side lateral raise", "élévations latérales",
            "élévation latérale", "épaules latérales", "alzate laterali", "alzata laterale",
        ]
        case .rearDeltFly: [
            "pájaros", "pájaro", "vuelos posteriores", "elevaciones posteriores", "aperturas invertidas", "rear delt",
            "rear delt fly", "rear delt flyes", "rear delt flies", "reverse fly", "reverse flyes", "reverse flies",
            "rear delt raise", "oiseau", "oiseaux", "élévations postérieures", "alzate posteriori",
            "deltoide posteriore",
        ]
        case .shrug: [
            "encogimientos", "encogimiento", "encogimientos de hombros", "encogimiento de hombros", "shrugs", "shrug",
            "haussements d'épaules", "élévation des épaules", "scrollate", "scrollate di spalle",
        ]
        case .uprightRow: [
            "remo al cuello", "remo al mentón", "upright row", "upright rows", "rowing menton", "tirate al mento",
            "tirata al mento",
        ]
        case .facePull: [
            "face pull", "face pulls", "jalón a la cara", "tirage visage", "tirage vers le visage",
        ]
        case .sitUp: [
            "sit up", "sit ups", "situps", "abdominales completos", "redressements assis",
        ]
        case .mountainClimber: [
            "mountain climbers", "mountain climber", "escaladores", "escalador", "grimpeur", "grimpeurs",
        ]
        }
    }
}

/// What draws a motion: the side view, or the front view for movements that open
/// sideways (FrontExercisePictogram).
enum PictogramDrawing {
    case side(ExercisePictogram)
    case front(FrontPictogram)

    func shapes(at progress: CGFloat) -> [PictogramShape] {
        switch self {
        case .side(let pictogram): pictogram.shapes(at: progress)
        case .front(let pictogram): pictogram.shapes(at: progress)
        }
    }
}
