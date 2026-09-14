//
//  RoutineImportTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  The mapping rules between what the model read and the real model, tested without the
//  LLM or a store. The template-session tests pin the promise that made "don't touch the
//  model" viable: an imported plan pre-fills the log but is never counted as training.
//

import Testing
@testable import MuscleCheck
import Foundation

@MainActor
struct RoutineImportTests {

    private func item(_ name: String, sets: Int? = nil, reps: String? = nil, muscle: TargetMuscle? = nil,
                      written: String? = nil, low: Bool = false) -> ScannedRoutine.Item {
        .init(name: name, sets: sets, repsText: reps, muscle: muscle, writtenGroup: written, lowConfidence: low)
    }

    private func draft(_ name: String, sets: Int? = nil, reps: Int? = nil,
                       group: ScannedExerciseDraft.GroupChoice?) -> ScannedExerciseDraft {
        ScannedExerciseDraft(name: name, sets: sets, reps: reps, group: group)
    }

    /// For imports that must not create any group.
    private func noNewGroup(_ name: String) -> MuscleEntry {
        Issue.record("Unexpected group creation: \(name)")
        return MuscleEntry(name: name)
    }

    // MARK: - parseReps

    @Test(arguments: [("8-12", 8), ("10", 10), ("12-10-8", 8), ("8 a 12", 8), ("8–12", 8), (" 15 ", 15)])
    func parseRepsKeepsTheLowestNumber(text: String, expected: Int) {
        #expect(RoutineImport.parseReps(text) == expected)
    }

    @Test(arguments: ["", "AMRAP", "al fallo", "0"])
    func parseRepsWithoutAPositiveNumberIsNil(text: String) {
        #expect(RoutineImport.parseReps(text) == nil)
    }

    // MARK: - Read → drafts

    @Test
    func draftsValidateWhatTheModelRead() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        let espalda = MuscleEntry(name: "Espalda", category: "gym")
        let routine = ScannedRoutine(items: [
            item("  Press banca ", sets: 4, reps: " 8-12 ", muscle: .chest),
            item("Remo", written: "espalda"),
            item("Hip thrust", written: "Glúteos"),
            item("Plancha"),
            item("Curl", sets: 45),
            item("   "),
        ])

        let drafts = RoutineImport.drafts(from: routine, groups: [pecho, espalda])

        #expect(drafts.map(\.name) == ["Press banca", "Remo", "Hip thrust", "Plancha", "Curl"])
        #expect(drafts[0].group == .existing(pecho.id))
        #expect(drafts[0].sets == 4)
        // Stored value is the range's minimum; the literal is kept for the hint.
        #expect(drafts[0].reps == 8)
        #expect(drafts[0].repRange == "8-12")
        // The sheet's heading matches a group (case-insensitively).
        #expect(drafts[1].group == .existing(espalda.id))
        // Unknown heading → proposed as a new group.
        #expect(drafts[2].group == .new("Glúteos"))
        #expect(drafts[2].suggestedGroupName == "Glúteos")
        // Nothing to go on → the user picks.
        #expect(drafts[3].group == nil)
        // 45 sets is a misread: dropped and flagged.
        #expect(drafts[4].sets == nil)
        #expect(drafts[4].lowConfidence)
    }

    @Test(arguments: [(12, 3, true), (14, 8, true), (8, 4, true), (4, 8, false), (5, 5, false), (6, 3, false), (3, 12, false)])
    func setsAndRepsInTheUnusualOrderAreSuspicious(sets: Int, reps: Int, suspicious: Bool) {
        #expect(RoutineImport.setsAndRepsLookSwapped(sets: sets, reps: reps) == suspicious)
    }

    @Test
    func aSuspiciousOrderIsFlaggedButNeverSwapped() {
        let routine = ScannedRoutine(items: [
            item("Prensa", sets: 14, reps: "8"),
            item("Press banca", sets: 4, reps: "8-12"),
            item("Dominadas", sets: 8),
        ])

        let drafts = RoutineImport.drafts(from: routine, groups: [])

        // Flagged for the user to confirm, values kept exactly as read.
        #expect(drafts[0].lowConfidence)
        #expect(drafts[0].sets == 14)
        #expect(drafts[0].reps == 8)
        #expect(drafts[0].repRange == nil)
        // The usual order stays quiet.
        #expect(!drafts[1].lowConfidence)
        // No reps to compare against: nothing to suspect.
        #expect(!drafts[2].lowConfidence)
    }

    @Test
    func theSheetsRepsLiteralIsKeptOnlyWhenItSaysMore() {
        let drafts = RoutineImport.drafts(from: ScannedRoutine(items: [
            item("Remo", sets: 4, reps: "10"),
            item("Fondos", sets: 3, reps: "AMRAP"),
            item("Curl", sets: 3, reps: "12-10-8"),
        ]), groups: [])

        #expect(drafts[0].reps == 10)
        #expect(drafts[0].repRange == nil)
        #expect(drafts[1].reps == nil)
        #expect(drafts[1].repRange == "AMRAP")
        #expect(drafts[2].reps == 8)
        #expect(drafts[2].repRange == "12-10-8")
    }

    @Test(arguments: [(14, 8, true), (11, 10, true), (10, 8, false), (12, 12, false), (8, 4, false), (4, 8, false)])
    func onlyAClearlyBackwardsPairOffersTheSwap(sets: Int, reps: Int, offersSwap: Bool) {
        #expect(RoutineImport.setsAndRepsLookImplausible(sets: sets, reps: reps) == offersSwap)
    }

    @Test
    func twoTiersDotForDoubtSwapOnlyWhenClearlyBackwards() {
        let drafts = RoutineImport.drafts(from: ScannedRoutine(items: [
            item("Sentadilla", sets: 8, reps: "4"),
            item("Prensa", sets: 14, reps: "8"),
        ]), groups: [])

        // 8×4: doubtful (dot) but plausible — no swap offered.
        #expect(drafts[0].lowConfidence)
        #expect(!drafts[0].suggestsSwap)
        // 14×8: doubtful AND clearly backwards.
        #expect(drafts[1].lowConfidence)
        #expect(drafts[1].suggestsSwap)
    }

    // MARK: - Review edits

    @Test
    func swappingResolvesTheDoubt() {
        var draft = ScannedExerciseDraft(name: "Prensa", sets: 14, reps: 8, repRange: "8-12", lowConfidence: true)

        draft.swapSetsAndReps()

        #expect(draft.sets == 8)
        #expect(draft.reps == 14)
        #expect(draft.repRange == nil)
        #expect(!draft.lowConfidence)
        #expect(!draft.suggestsSwap)
    }

    @Test
    func theRangeHintGoesAwayOnceTheRepsAreEdited() {
        var draft = ScannedExerciseDraft(name: "Press banca", sets: 4, reps: 8, repRange: "8-12")
        #expect(draft.repRangeHint == "8-12")

        draft.reps = 10

        #expect(draft.repRangeHint == nil)
    }

    // MARK: - Group assignment

    private func group(_ name: String, trainedDaysAgo: Int? = nil, exercises: [String] = []) -> MuscleEntry {
        let entry = MuscleEntry(name: name, category: "gym")
        if let trainedDaysAgo {
            entry.addSession(Calendar.current.date(byAdding: .day, value: -trainedDaysAgo, to: Date())!)
        }
        exercises.forEach { entry.addExercise(name: $0, metric: .strength, icon: "x") }
        return entry
    }

    private func groupFor(_ item: ScannedRoutine.Item, in groups: [MuscleEntry]) -> ScannedExerciseDraft.GroupChoice? {
        RoutineImport.drafts(from: ScannedRoutine(items: [item]), groups: groups).first?.group
    }

    @Test
    func anExerciseTheUserAlreadyHasGoesToItsGroupWhateverTheModelSays() {
        // The field bug: "Prensa" sat in Legs and the model put it in Back.
        let back = group("Back")
        let legs = group("Legs", exercises: ["Prensa"])

        #expect(groupFor(item("prensa", muscle: .back), in: [back, legs]) == .existing(legs.id))
    }

    @Test
    func exerciseMatchingIgnoresCaseAndAccents() {
        let piernas = group("Piernas", exercises: ["Sentadilla búlgara"])

        #expect(groupFor(item("SENTADILLA BULGARA"), in: [piernas]) == .existing(piernas.id))
    }

    @Test
    func theSameMuscleInTwoLanguagesPicksTheOneInUse() {
        let back = group("Back", trainedDaysAgo: 30)
        let espalda = group("Espalda", trainedDaysAgo: 1)

        #expect(groupFor(item("Remo", muscle: .back), in: [back, espalda]) == .existing(espalda.id))
    }

    @Test
    func neverTrainedDuplicatesPickTheOneWithMoreExercises() {
        let chest = group("Chest")
        let pecho = group("Pecho", exercises: ["Press banca", "Aperturas"])

        #expect(groupFor(item("Fondos", muscle: .chest), in: [chest, pecho]) == .existing(pecho.id))
    }

    @Test
    func aSingleMuscleGroupBeatsACombinedOne() {
        let combined = group("Pecho y tríceps", trainedDaysAgo: 1)
        let triceps = group("Tricep", trainedDaysAgo: 20)

        #expect(groupFor(item("Press francés", muscle: .triceps), in: [combined, triceps]) == .existing(triceps.id))
    }

    @Test
    func aMuscleWithoutAGroupProposesOneInTheAppLanguage() {
        let pecho = group("Pecho")

        let drafts = RoutineImport.drafts(from: ScannedRoutine(items: [item("Hip thrust", muscle: .glutes)]), groups: [pecho])

        #expect(drafts[0].group == .new(TargetMuscle.glutes.localizedName))
        #expect(drafts[0].suggestedGroupName == TargetMuscle.glutes.localizedName)
    }

    @Test
    func theSheetsHeadingBeatsTheModelsGuess() {
        let piernas = group("Piernas")
        let gluteos = group("Glúteos")

        #expect(groupFor(item("Hip thrust", muscle: .glutes, written: "Piernas"), in: [gluteos, piernas]) == .existing(piernas.id))
    }

    @Test
    func aHeadingThatNamesAMuscleFindsTheGroupInAnyLanguage() {
        let legs = group("Legs")

        #expect(groupFor(item("Prensa", written: "Día 1 - Cuádriceps"), in: [legs]) == .existing(legs.id))
    }

    @Test
    func aFreeFormHeadingWithNoMuscleIsProposedAsItIs() {
        #expect(groupFor(item("Prensa", written: "Día 1"), in: [group("Pecho")]) == .new("Día 1"))
    }

    @Test
    func theOwnersScanNowLandsInTheRightGroups() {
        // The owner's real gym groups (two languages) and the sheet that went wrong.
        let names = ["Abdomen", "Back", "Bicep", "Biceps", "Chest", "Core", "Espalda", "Legs", "Pecho", "Piernas", "Shoulders", "Tricep", "Triceps"]
        var groups = names.map { group($0) }
        let legs = group("Legs", trainedDaysAgo: 9, exercises: ["Prensa", "Sentadilla"])
        let piernas = group("Piernas", trainedDaysAgo: 2)
        groups[groups.firstIndex { $0.name == "Legs" }!] = legs
        groups[groups.firstIndex { $0.name == "Piernas" }!] = piernas

        let drafts = RoutineImport.drafts(from: ScannedRoutine(items: [
            item("Bulgares", sets: 3, reps: "12", muscle: .legs),
            item("Prensa", sets: 4, reps: "8", muscle: .legs),
            item("Sentadilla", sets: 4, reps: "10", muscle: .legs),
        ]), groups: groups)

        // Never Shoulders / Back again.
        #expect(drafts[0].group == .existing(piernas.id))   // new exercise → the legs group in use
        #expect(drafts[1].group == .existing(legs.id))      // already in Legs → stays with it
        #expect(drafts[2].group == .existing(legs.id))
    }

    // MARK: - Drafts → model

    @Test
    func importAddsTheExerciseWithATemplateSession() throws {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")

        let result = RoutineImport.apply(
            [draft("Press banca", sets: 4, reps: 8, group: .existing(pecho.id))],
            groups: [pecho],
            createGroup: noNewGroup
        )

        #expect(result == RoutineImport.Result(added: 1, skippedDuplicates: 0, createdGroups: 0))
        let exercise = try #require(pecho.exercises.first)
        #expect(exercise.name == "Press banca")
        #expect(exercise.metric == .strength)
        #expect(exercise.sessions.count == 1)
        #expect(RoutineImport.isTemplate(exercise.sessions[0]))
        // What SessionLogView pre-fills from. Range → its minimum.
        #expect(exercise.lastSets == 4)
        #expect(exercise.lastReps == 8)
    }

    @Test
    func theTemplateSessionIsNeverCountedAsTraining() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        RoutineImport.apply(
            [draft("Press banca", sets: 4, reps: 10, group: .existing(pecho.id))],
            groups: [pecho],
            createGroup: noNewGroup
        )

        #expect(pecho.sessions.isEmpty)
        #expect(!pecho.isTrained(inWeekOf: Date()))

        // Even on a day the group IS trained, the plan doesn't show up as done.
        pecho.addSession(Date())
        let week = MonthCalendarCalculator.weekBreakdown(forWeekContaining: Date(), from: [pecho])
        #expect(week.count == 1)
        #expect(week.first?.activities.first?.exercises.isEmpty == true)
    }

    @Test
    func theFirstRealLogSupersedesTheTemplate() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        RoutineImport.apply(
            [draft("Press banca", sets: 4, reps: 8, group: .existing(pecho.id))],
            groups: [pecho],
            createGroup: noNewGroup
        )

        pecho.logExercise(id: pecho.exercises[0].id, input: SessionInput(weightKg: 60, sets: 3, reps: 10))

        #expect(pecho.exercises[0].lastSets == 3)
        #expect(pecho.exercises[0].lastReps == 10)
        #expect(pecho.exercises[0].lastWeight == 60)
        #expect(pecho.isTrained(inWeekOf: Date()))
    }

    @Test
    func anExerciseWithoutSetsOrRepsGetsNoSession() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")

        RoutineImport.apply([draft("Fondos", group: .existing(pecho.id))], groups: [pecho], createGroup: noNewGroup)

        #expect(pecho.exercises.count == 1)
        #expect(pecho.exercises[0].sessions.isEmpty)
    }

    @Test
    func duplicatesAreSkippedAndTheExistingExerciseIsUntouched() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        pecho.addExercise(name: "Press Banca", metric: .strength, icon: "x")

        let result = RoutineImport.apply(
            [draft(" press banca ", sets: 5, reps: 5, group: .existing(pecho.id))],
            groups: [pecho],
            createGroup: noNewGroup
        )

        #expect(result == RoutineImport.Result(added: 0, skippedDuplicates: 1, createdGroups: 0))
        #expect(pecho.exercises.count == 1)
        #expect(pecho.exercises[0].sessions.isEmpty)
    }

    @Test
    func aNewGroupIsCreatedOnceForAllItsExercises() {
        var created: [MuscleEntry] = []

        let result = RoutineImport.apply(
            [draft("Hip thrust", group: .new("Glúteos")), draft("Patada", group: .new(" glúteos "))],
            groups: []
        ) { name in
            let entry = MuscleEntry(name: name, category: "gym", metric: .strength)
            created.append(entry)
            return entry
        }

        #expect(created.map(\.name) == ["Glúteos"])
        #expect(result == RoutineImport.Result(added: 2, skippedDuplicates: 0, createdGroups: 1))
        #expect(created.first?.exercises.map(\.name) == ["Hip thrust", "Patada"])
    }

    @Test
    func aNewGroupNamedLikeAnyExistingEntryReusesItAndOpensItsDetail() {
        // Not a gym group, and check-only: it has no detail screen until it has a metric.
        let core = MuscleEntry(name: "Core", category: "calisthenics")
        #expect(core.metric == .none)

        let result = RoutineImport.apply([draft("Plancha", group: .new("core"))], groups: [core], createGroup: noNewGroup)

        #expect(result.createdGroups == 0)
        #expect(core.exercises.map(\.name) == ["Plancha"])
        #expect(core.metric == .strength)
    }

    @Test
    func rowsThatAreNotImportableAreIgnored() {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")

        let result = RoutineImport.apply(
            [draft("  ", group: .existing(pecho.id)), draft("Remo", group: nil), draft("Remo", group: .new("  "))],
            groups: [pecho],
            createGroup: noNewGroup
        )

        #expect(result == RoutineImport.Result())
        #expect(pecho.exercises.isEmpty)
    }
}
