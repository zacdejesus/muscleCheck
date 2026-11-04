//
//  ExerciseMotionTests.swift
//  MuscleCheckTests
//
//  Which pictogram the AI coach card draws for an exercise name. A wrong drawing is worse
//  than none, so besides "finds the right one" these pin down the names that must find
//  nothing.
//

import Testing
@testable import MuscleCheck

struct ExerciseMotionTests {

    @Test("Every phrase of a motion resolves back to that motion", arguments: ExerciseMotion.allCases)
    func phrasesResolveToTheirOwnMotion(motion: ExerciseMotion) {
        #expect(!motion.phrases.isEmpty)
        for phrase in motion.phrases {
            #expect(ExerciseCatalog.motion(for: phrase) == motion, "\"\(phrase)\"")
        }
    }

    @Test("A motion's phrases tell the routine scan the same muscle", arguments: ExerciseMotion.allCases)
    func phrasesAgreeWithTheScanMuscle(motion: ExerciseMotion) {
        for phrase in motion.phrases {
            #expect(ExerciseCatalog.lookup(phrase) == .known(motion.muscle), "\"\(phrase)\"")
        }
    }

    @Test(arguments: [
        // The specific variant we don't draw wins over the generic one we do.
        ("Hack squat", nil), ("Patada de glúteo", nil), ("Glute kickback", nil), ("Plank laterale", nil),
        // ...and the specific one we do draw wins too.
        ("Sentadilla búlgara", ExerciseMotion.bulgarianSplitSquat), ("Goblet squat", .gobletSquat),
        ("Straight arm pulldown", .straightArmPulldown), ("Remo al cuello", .uprightRow),
        ("Rear delt fly", .rearDeltFly), ("Cable fly", .cableCrossover), ("Encogimientos abdominales", .crunch),
        // Too generic to draw.
        ("Press", nil),
        // Plurals the coach writes that aren't listed.
        ("Bent-over rows", .barbellRow), ("Seated cable rows", .seatedCableRow), ("Leg presses", .legPress),
        // Front views.
        ("Elevaciones laterales", .lateralRaise), ("Lateral raise", .lateralRaise), ("Aperturas", .dumbbellFly),
        // Equipment and variants pick their own drawing.
        ("Curl con mancuernas", ExerciseMotion.dumbbellCurl), ("Curl martillo", .hammerCurl),
        ("Curl femoral", .legCurl), ("Curl de muñeca", nil), ("Peso muerto rumano", .romanianDeadlift),
        ("Peso muerto", .deadlift), ("Trazioni alla lat machine", .latPulldown), ("Fondos en banco", .benchDip),
        ("Extensión de tríceps con cuerda", .cablePushdown), ("Military press con manubri", .seatedDumbbellPress),
    ] as [(String, ExerciseMotion?)])
    func specificNamesWinOverGenericOnes(name: String, expected: ExerciseMotion?) {
        #expect(ExerciseCatalog.motion(for: name) == expected)
    }

    /// Exercise names the on-device coach actually wrote (84 suggestions over ES/EN/FR/IT,
    /// generated with the app's prompts on 2026-11-04), each reviewed by hand. nil means no
    /// drawing fits: names that don't describe a real exercise ("Press de bíceps con
    /// mancuernas"). A confused name still gets
    /// the drawing its words describe ("Press inclinado de bíceps" → incline press); shorthand
    /// too vague to pin down ("Frontali con cavo basso", "Panca con manubri") gets none.
    @Test("Names the coach writes get the reviewed drawing", arguments: [
        // ES
        ("Press de pecho", .benchPress),
        ("Elevaciones laterales", .lateralRaise),
        ("Extensión de tríceps", .overheadTricepsExtension),
        ("Fondos en paralelas", .tricepsDip),
        ("Press de banca", .benchPress),
        ("Flexiones diamante", .pushUp),
        ("Curl de bíceps con barra", .barbellCurl),
        ("Press de bíceps con mancuernas", nil),
        ("Elevación de bíceps sentado", nil),
        ("Elevación lateral de peso muerto", .lateralRaise),
        ("Press militar con barra corta", .militaryPress),
        ("Elevaciones laterales de hombros", .lateralRaise),
        ("Elevaciones frontales de hombros", .frontRaise),
        ("Press inclinado de pecho", .inclineDumbbellPress),
        ("Cruces en poleas para hombros", .cableCrossover),
        ("Elevación lateral de pesas", .lateralRaise),
        ("Press inclinado con mancuernas", .inclineDumbbellPress),
        ("Extensión de tríceps con cuerda", .cablePushdown),
        ("Extensiones de tríceps con mancuerna", .overheadTricepsExtension),
        ("Press militar con barra", .militaryPress),
        ("Remo con barra", .barbellRow),
        ("Dominadas", .pullUp),
        ("Jalón al pecho", .latPulldown),
        ("Press francés", .skullCrusher),
        ("Curl martillo", .hammerCurl),
        ("Elevación lateral de bíceps", .lateralRaise),
        ("Sentadilla frontal", .squat),
        ("Elevación de pierna", .hangingLegRaise),
        ("Abducción de cadera", .hipAbduction),
        ("Press inclinado", .inclineDumbbellPress),
        ("Extensiones de tríceps", .overheadTricepsExtension),
        ("Curl de bíceps", .barbellCurl),
        ("Dominadas con barra", .pullUp),
        ("Press inclinado de bíceps", .inclineDumbbellPress),
        ("Elevaciones frontales", .frontRaise),
        ("Press de hombros", .seatedDumbbellPress),
        ("Press militar", .militaryPress),
        ("Aperturas con mancuernas", .dumbbellFly),
        ("Peso muerto rumano", .romanianDeadlift),
        ("Curl concentrado", .concentrationCurl),
        ("Zancadas", .lunge),
        ("Elevación de piernas", .hangingLegRaise),
        ("Press de banca con barra", .benchPress),
        ("Elevaciones laterales con mancuernas", .lateralRaise),
        ("Elevación de piernas colgado", .hangingLegRaise),
        ("Crunch con peso", .crunch),
        ("Plancha con elevación de pierna", nil),
        ("Elevaciones laterales de hombro", .lateralRaise),
        ("Extensiones de tríceps con barra", .skullCrusher),
        ("Elevaciones frontales con barra", .frontRaise),
        ("Flexiones en barra", .pushUp),
        ("Elevación lateral", .lateralRaise),
        ("Elevación de talones", .calfRaise),
        // EN
        ("Barbell Bench Press", .benchPress),
        ("Dumbbell Fly", .dumbbellFly),
        ("Cable Fly", .cableCrossover),
        ("Overhead Press", .militaryPress),
        ("Lateral Raise", .lateralRaise),
        ("Front Raise", .frontRaise),
        ("Chest Press", .benchPress),
        ("Shoulder Press", .seatedDumbbellPress),
        ("Triceps Pushdown", .cablePushdown),
        ("Ab Crunch", .crunch),
        ("Leg Raise", .hangingLegRaise),
        ("Plank Hold", .plank),
        ("Skull Crush", .skullCrusher),
        ("Close-Grip Bench", .closeGripBenchPress),
        ("Bench Press", .benchPress),
        ("Incline Dumbbell Press", .inclineDumbbellPress),
        ("Rear Delt Fly", .rearDeltFly),
        ("Chest Fly", .dumbbellFly),
        ("Lat Pulldown", .latPulldown),
        ("Seated Cable Row", .seatedCableRow),
        ("Straight Arm Pulldown", .straightArmPulldown),
        ("Hammer Curl", .hammerCurl),
        ("Concentration Curl", .concentrationCurl),
        ("Preacher Curl", .preacherCurl),
        ("Push-ups", .pushUp),
        ("Leg Extension", .legExtension),
        ("Calf Raise", .calfRaise),
        ("Skull Crusher", .skullCrusher),
        ("Close-Grip Bench Press", .closeGripBenchPress),
        ("Pull-Ups", .pullUp),
        ("Hammer Curls", .hammerCurl),
        ("Concentration Curls", .concentrationCurl),
        ("Preacher Curls", .preacherCurl),
        ("Triceps Dips", .tricepsDip),
        ("Squats", .squat),
        ("Lunges", .lunge),
        ("Leg Press", .legPress),
        ("Lateral Raises", .lateralRaise),
        ("Front Raises", .frontRaise),
        ("Rear Delt Flyes", .rearDeltFly),
        // FR
        ("Développé couché", .benchPress),
        ("Élévations latérales", .lateralRaise),
        ("Extensions triceps", .overheadTricepsExtension),
        ("Pompes", .pushUp),
        ("Dips", .tricepsDip),
        ("épaules latérales", .lateralRaise),
        ("extension des triceps", .overheadTricepsExtension),
        ("rowing barre", .barbellRow),
        ("tirage vertical", .latPulldown),
        ("pull-down dos", .latPulldown),
        ("Développé militaire", .militaryPress),
        ("Extensions de triceps", .overheadTricepsExtension),
        ("Pompes diamant", .pushUp),
        ("Élévation des épaules", .shrug),
        ("Dip sur barre", .tricepsDip),
        ("Élévation latérale", .lateralRaise),
        ("Extension triceps à la poulie", .cablePushdown),
        ("Élévation au-dessus de la tête", nil),
        ("Élévations au-dessus de la tête", nil),
        ("Extensions triceps à la poulie", .cablePushdown),
        ("Tirage horizontal", .seatedCableRow),
        ("Flexions du dos", nil),
        ("extension triceps", .overheadTricepsExtension),
        ("relevés de jambes", .hangingLegRaise),
        ("crunchs", .crunch),
        ("levés de jambes suspendus", .hangingLegRaise),
        ("épaules debout", nil),
        ("épaules frontales", nil),
        ("épaulage barre", nil),
        ("flexion de la triceps avec haltère", nil),
        ("Élévations frontales", .frontRaise),
        ("Élévations au corps", nil),
        ("tirage poitrine", .latPulldown),
        ("extension du dos", .backExtension),
        ("planche basse", .plank),
        ("Élévations latérales au câble", .lateralRaise),
        ("Extensions de triceps à la poulie", .cablePushdown),
        ("décliné couché", .declineBenchPress),
        ("Pompes au triceps", .pushUp),
        ("Curl barre", .barbellCurl),
        ("Curl haltères", .dumbbellCurl),
        ("Curl prise neutre", .hammerCurl),
        // IT
        ("Panca piana con bilanciere", .benchPress),
        ("Alzate laterali con manubri", .lateralRaise),
        ("Crossover con cavo basso", .cableCrossover),
        ("Pushdown con cavo alto", .cablePushdown),
        ("French press con manubrio", .overheadTricepsExtension),
        ("Estensioni laterali con cavo alto", nil),
        ("Push-up con carico aggiuntivo", .pushUp),
        ("Rematore con barra", .barbellRow),
        ("Lat machine con presa larga", .latPulldown),
        ("Trazioni alla sbarra", .pullUp),
        ("Panca piana", .benchPress),
        ("Military press", .militaryPress),
        ("French press", .skullCrusher),
        ("Pushdown con cavo", .cablePushdown),
        ("Push-down con cavo", .cablePushdown),
        ("Estensioni laterali con cavo", nil),
        ("Skull crusher con bilanciere", .skullCrusher),
        ("Alzate frontali con manubri", .frontRaise),
        ("Military press con bilanciere", .militaryPress),
        ("Frontali con cavo basso", nil),
        ("alzate laterali", .lateralRaise),
        ("dip alle parallele", .tricepsDip),
        ("rematore con bilanciere", .barbellRow),
        ("pull-down con cavo", .latPulldown),
        ("trazioni alla lat machine", .latPulldown),
        ("squat con bilanciere", .squat),
        ("stacco da terra", .deadlift),
        ("affondi con manubri", .lunge),
        ("Push-down con cavo basso", .cablePushdown),
        ("Push-up con peso aggiuntivo", .pushUp),
        ("Trazioni alla sbarra con presa neutra", .pullUp),
        ("Crossover con cavo", .cableCrossover),
        ("Alzate frontali", .frontRaise),
        ("Front raise con manubri", .frontRaise),
        ("panca inclinata con bilanciere", .inclineDumbbellPress),
        ("panca con manubri", nil),
        ("Rematore con manubrio", .oneArmDumbbellRow),
        ("Circonduzioni laterali con cavo", nil),
        ("Curl con manubrio", .dumbbellCurl),
        ("Curl con barra dritta", .barbellCurl),
        ("Curl concentrato con manubrio", .concentrationCurl),
        ("squat", .squat),
        ("affondi camminati", .lunge),
        ("Tricipiti alla corda", .cablePushdown),
        ("Affondi con bilanciere", .lunge),
        ("Crunch con sovraccarico", .crunch),
        ("Frontale con manubri", nil),
        ("Posterior deltoide con cavo", nil),
        ("Shrugs", .shrug),
        ("Military press con manubri", .seatedDumbbellPress),
        ("Rotazioni laterali con cavo", nil),
    ] as [(String, ExerciseMotion?)])
    func coachSampleNames(name: String, expected: ExerciseMotion?) {
        #expect(ExerciseCatalog.motion(for: name) == expected)
    }
}
