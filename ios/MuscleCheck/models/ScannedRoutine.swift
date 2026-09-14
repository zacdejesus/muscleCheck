//
//  ScannedRoutine.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  Version-agnostic side of the scan feature. The iOS-27-only `@Generable` output
//  (RoutineScanAI.swift) is mapped to `ScannedRoutine` right at the AI boundary, so the
//  view model and the review screen (iOS 18 target) never touch FoundationModels —
//  the same split as `WorkoutSuggestion` → `RoutineSuggestion` in the AI Coach.
//
//  Two shapes on purpose:
//  - `ScannedRoutine` is what the model READ: immutable, possibly partial or wrong.
//  - `ScannedExerciseDraft` is what the user EDITS on the review screen. Nothing is
//    persisted until the user confirms the drafts.
//

import Foundation

struct ScannedRoutine: Equatable {

    struct Item: Equatable {
        let name: String
        /// Nil when the sheet doesn't say it or the model couldn't read it.
        let sets: Int?
        /// As written — ranges like "8-12" are kept verbatim; `RoutineImport` decides what
        /// gets stored.
        let repsText: String?
        /// Main muscle the model says the exercise trains; nil for cardio, full body or unsure.
        /// `RoutineImport` maps it to the user's groups — never an index into their list.
        let muscle: TargetMuscle?
        /// Group heading written on the sheet ("Pecho", "Día 1 — Piernas"), if any.
        let writtenGroup: String?
        let lowConfidence: Bool
    }

    let items: [Item]
}

/// One editable card of the review screen.
struct ScannedExerciseDraft: Identifiable, Equatable {

    enum GroupChoice: Hashable {
        /// One of the user's existing groups.
        case existing(UUID)
        /// A group created on import, named as typed (or as read from the sheet).
        case new(String)
    }

    let id: UUID
    var name: String
    var sets: Int?
    /// The value that gets stored: the lowest number of the sheet's text.
    var reps: Int?
    /// The sheet's literal when it said more than a plain number ("8-12", "AMRAP"), shown
    /// as a hint next to the stored value.
    var repRange: String?
    var group: GroupChoice?
    /// The model flagged the row, or its numbers look read in the unusual order. Amber dot.
    var lowConfidence: Bool
    /// Pre-fill for "Grupo nuevo" — the heading read from the sheet, if any.
    var suggestedGroupName: String

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int? = nil,
        reps: Int? = nil,
        repRange: String? = nil,
        group: GroupChoice? = nil,
        lowConfidence: Bool = false,
        suggestedGroupName: String = ""
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.repRange = repRange
        self.group = group
        self.lowConfidence = lowConfidence
        self.suggestedGroupName = suggestedGroupName
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What blocks the import: a card needs a group to land in.
    var hasValidGroup: Bool {
        switch group {
        case .existing: return true
        case .new(let name): return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case nil: return false
        }
    }

    var isImportable: Bool { !trimmedName.isEmpty && hasValidGroup }

    /// Strong signal that the pair was read backwards → the card offers "Dar vuelta".
    var suggestsSwap: Bool {
        RoutineImport.setsAndRepsLookImplausible(sets: sets, reps: reps)
    }

    /// The sheet's literal, only while `reps` is still the value derived from it — once the
    /// user types another number the hint would describe something that's no longer there.
    var repRangeHint: String? {
        guard let repRange, reps == RoutineImport.parseReps(repRange) else { return nil }
        return repRange
    }

    /// "Dar vuelta": the user confirmed the pair was backwards, so the doubt is resolved.
    mutating func swapSetsAndReps() {
        (sets, reps) = (reps, sets)
        repRange = nil
        lowConfidence = false
    }
}
