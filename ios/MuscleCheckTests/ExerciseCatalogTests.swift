//
//  ExerciseCatalogTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  The table that decides an exercise's muscle instead of the on-device model, which names
//  muscles by how words sound ("Prensa" → chest).
//

import Testing
@testable import MuscleCheck

struct ExerciseCatalogTests {

    @Test(arguments: [
        ("Prensa", TargetMuscle.legs), ("Leg press", .legs), ("Press de piernas", .legs), ("Press banca", .chest),
        ("Press inclinado mancuernas", .chest), ("Press militar", .shoulders), ("Press francés", .triceps),
        ("Jalón al pecho", .back), ("Aperturas", .chest), ("Gemelos de pie", .calves), ("Pull-ups", .back),
        ("Curl femoral", .legs), ("Curl martillo", .biceps), ("Curl de muñeca", .forearms), ("Elevación de piernas", .core),
        ("Encogimientos", .shoulders), ("Patada de tríceps", .triceps), ("PATADA", .glutes), ("Développé couché", .chest),
        ("Panca piana", .chest), ("Lat machine", .back), ("Bulgares", .legs), ("Peso muerto rumano", .legs),
        ("Peso muerto", .back), ("Remo al cuello", .shoulders), ("Hip thrust", .glutes), ("Fondos", .triceps),
    ])
    func knownExercisesMapToTheirMuscle(name: String, muscle: TargetMuscle) {
        #expect(ExerciseCatalog.lookup(name) == .known(muscle))
    }

    @Test(arguments: ["Cinta 20 min", "Burpees", "Bici", "Saltos al cajón"])
    func cardioIsKnownButHasNoMuscle(name: String) {
        #expect(ExerciseCatalog.lookup(name) == .known(nil))
    }

    @Test(arguments: ["Movilidad de cadera", "Día 1", ""])
    func unknownNamesFallThrough(name: String) {
        #expect(ExerciseCatalog.lookup(name) == .unknown)
    }

    @Test
    func theMostSpecificPhraseWins() {
        #expect(ExerciseCatalog.lookup("Curl") == .known(.biceps))
        #expect(ExerciseCatalog.lookup("Curl femoral acostado") == .known(.legs))
        #expect(ExerciseCatalog.lookup("Encogimientos abdominales") == .known(.core))
        #expect(ExerciseCatalog.lookup("Remo al cuello") == .known(.shoulders))
        #expect(ExerciseCatalog.lookup("Remo ergómetro 10 min") == .known(nil))
    }
}
