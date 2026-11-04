//
//  TargetMuscleTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  The synonym table that lets the app know "Chest" and "Pecho" are the same muscle.
//

import Testing
@testable import MuscleCheck
import Foundation

struct TargetMuscleTests {

    @Test(arguments: ["Chest", "Pecho", "PECTORALES", "Poitrine", "Pettorali", "pecs"])
    func chestInEveryLanguage(name: String) {
        #expect(TargetMuscle.muscles(inName: name) == [.chest])
    }

    @Test(arguments: [
        ("Bicep", TargetMuscle.biceps), ("Bíceps", .biceps), ("Tricep", .triceps), ("Abdomen", .core),
        ("Abdominales", .core), ("Core", .core), ("Gemelos", .calves), ("Glúteos", .glutes),
        ("Avant-bras", .forearms), ("Espalda", .back), ("Dos", .back), ("Épaules", .shoulders),
    ])
    func synonymsAcrossLanguagesAndAccents(name: String, muscle: TargetMuscle) {
        #expect(TargetMuscle.muscles(inName: name) == [muscle])
    }

    @Test
    func aCombinedGroupNamesEveryMuscle() {
        #expect(TargetMuscle.muscles(inName: "Pecho y tríceps") == [.chest, .triceps])
    }

    @Test(arguments: ["Día 1", "Día dos", "Ir para atras", "Patín", "Full body", ""])
    func freeFormNamesAreNoMuscle(name: String) {
        #expect(TargetMuscle.muscles(inName: name).isEmpty)
    }

    @Test
    func aProposedGroupNameIsRecognizedAsItsMuscle() {
        for muscle in TargetMuscle.allCases {
            #expect(!muscle.localizedName.hasPrefix("group_"))
            #expect(TargetMuscle.muscles(inName: muscle.localizedName).contains(muscle))
        }
    }

    // MARK: - Duplicates across languages

    @Test
    func aPresetInAnotherLanguageRepeatsTheMuscle() {
        #expect(TargetMuscle.repeatsMuscle(ofName: "Pecho", in: [MuscleEntry(name: "Chest", category: "gym")]))
        #expect(TargetMuscle.repeatsMuscle(ofName: "Abdomen", in: [MuscleEntry(name: "Core", category: "gym")]))
    }

    @Test
    func sameNameCombinedAndFreeFormNamesDoNotRepeat() {
        // Identical names are the regular duplicate rule's job.
        #expect(!TargetMuscle.repeatsMuscle(ofName: "Pecho", in: [MuscleEntry(name: "pecho", category: "gym")]))
        // A combined group neither covers nor is covered.
        #expect(!TargetMuscle.repeatsMuscle(ofName: "Pecho", in: [MuscleEntry(name: "Pecho y tríceps", category: "gym")]))
        #expect(!TargetMuscle.repeatsMuscle(ofName: "Pecho y tríceps", in: [MuscleEntry(name: "Pecho", category: "gym")]))
        #expect(!TargetMuscle.repeatsMuscle(ofName: "Vinyasa", in: [MuscleEntry(name: "Hatha", category: "yoga")]))
    }

    @Test
    func onePerMuscleKeepsTheGroupInUseAndTheOrder() {
        let chest = MuscleEntry(name: "Chest", category: "gym")
        let espalda = MuscleEntry(name: "Espalda", category: "gym")
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        pecho.addSession(Date())
        let combined = MuscleEntry(name: "Pecho y tríceps", category: "gym")
        let free = MuscleEntry(name: "Día 1", category: "gym")

        let kept = GroupRanking.onePerMuscle([chest, espalda, pecho, combined, free])

        #expect(kept.map(\.name) == ["Espalda", "Pecho", "Pecho y tríceps", "Día 1"])
    }

    @Test
    func foldingIgnoresCaseAccentsAndPunctuation() {
        #expect(NameMatching.fold("  Sentadilla  BÚLGARA—con mancuernas ") == "sentadilla bulgara con mancuernas")
    }
}
