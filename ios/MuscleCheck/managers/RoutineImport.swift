//
//  RoutineImport.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  Pure mapping between what the scanner read and the user's real model. No
//  FoundationModels and no SwiftData context: groups come in as values and new groups
//  are created through an injected closure, so every rule here is unit-testable without
//  the LLM or a store.
//
//  The data model is NOT changed. A paper routine is a PLAN ("4×8-12") while
//  `WorkoutSession` is HISTORY (what was done on a date), so the plan is stored as one
//  *template session* on the exercise:
//  - dated `templateSessionDate` (the distant past), so it never shares a day with a
//    group session: the check, streak, stats and calendar read the GROUP's sessions, and
//    the week detail only lists an exercise on days its group was trained;
//  - `Exercise.lastSets` / `lastReps` fall back to it, so `SessionLogView` opens
//    pre-filled with the routine's sets and reps until the first real log supersedes it.
//

import Foundation

enum RoutineImport {

    /// The one sentinel date for template sessions. Checks go through `isTemplate(_:)` so
    /// the magic value lives in exactly one place.
    static let templateSessionDate = Date.distantPast

    static func isTemplate(_ session: WorkoutSession) -> Bool {
        session.date == templateSessionDate
    }

    /// Sets a routine sheet can plausibly prescribe. Anything else is a misread.
    static let plausibleSets = 1...20

    /// SOFT signal (amber dot). Routines are written SETS × REPS ("4×8"), but some coaches
    /// write it the other way round ("12×3" = 3 sets of 12). The model is told the
    /// convention and never swaps; this catches rows transcribed in the unusual order.
    static func setsAndRepsLookSwapped(sets: Int?, reps: Int?) -> Bool {
        guard let sets, let reps else { return false }
        return sets > 6 && sets > reps
    }

    /// STRONG signal (hint + one-tap "Dar vuelta"). More than 10 sets of 10 reps or fewer
    /// ("14×8") is almost certainly backwards. A heavy "8×3" only gets the soft dot: it can
    /// be real, and the card shouldn't keep offering to break it.
    static func setsAndRepsLookImplausible(sets: Int?, reps: Int?) -> Bool {
        guard let sets, let reps else { return false }
        return sets > 10 && reps <= 10
    }

    /// Reps to store from the text as written. Ranges and pyramids keep the LOWEST number
    /// ("8-12" → 8, "12-10-8" → 8): where a progressive-overload range starts.
    /// Nil when there's no positive number ("AMRAP", "al fallo", "").
    static func parseReps(_ text: String) -> Int? {
        text.split { !("0"..."9").contains($0) }
            .compactMap { Int($0) }
            .filter { $0 > 0 }
            .min()
    }

    // MARK: - Read → drafts

    /// Placeholder names the model emits for rows it makes up on images that aren't routines
    /// (in the on-device evaluation a blank page produced rows called "none" with "4x8-12").
    private static let placeholderNames: Set<String> = ["none", "null", "nil", "n a", "na", "ninguno", "ninguna", "nada", "unknown", "desconocido"]

    /// The model sometimes writes the whole "sets × reps" pair in the reps field ("5x5",
    /// "4 x 8-12") or keeps the separator ("x8"). Returns the sets found in the pair, if any, and
    /// the reps part alone. Anything else comes back untouched.
    static func splitSetsAndReps(_ text: String) -> (sets: Int?, reps: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separators: Set<Character> = ["x", "X", "×", "*"]
        guard let index = trimmed.firstIndex(where: { separators.contains($0) }) else { return (nil, trimmed) }
        let left = trimmed[..<index].trimmingCharacters(in: .whitespaces)
        let right = trimmed[trimmed.index(after: index)...].trimmingCharacters(in: .whitespaces)
        guard parseReps(right) != nil else { return (nil, trimmed) }
        if left.isEmpty { return (nil, right) }
        guard let sets = Int(left) else { return (nil, trimmed) }
        return (sets, right)
    }

    /// Turns what the model read into editable cards, validating everything the model can get
    /// wrong: implausible sets, sets and reps in one field, sets/reps in the unusual order,
    /// placeholder or blank names — and choosing each card's group in code (`groupChoice`).
    /// - Parameter groups: the gym groups the review picker offers; every guess lands in one.
    @MainActor
    static func drafts(from routine: ScannedRoutine, groups: [MuscleEntry]) -> [ScannedExerciseDraft] {
        routine.items.compactMap { item in
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !placeholderNames.contains(NameMatching.fold(name)) else { return nil }

            let readSets = item.sets.flatMap { plausibleSets.contains($0) ? $0 : nil }
            let setsMisread = item.sets != nil && readSets == nil
            let pair = splitSetsAndReps(item.repsText ?? "")
            // "5x5" landed whole in reps while sets came back empty or as 1: trust the pair.
            var sets = readSets
            if let pairSets = pair.sets, plausibleSets.contains(pairSets),
               readSets == nil || readSets == 1 || readSets == pairSets {
                sets = pairSets
            }
            let reps = parseReps(pair.reps)
            // Keep the literal only when it says more than the stored number.
            let repRange = (pair.reps.isEmpty || pair.reps == reps.map(String.init)) ? nil : pair.reps

            return ScannedExerciseDraft(
                name: name,
                sets: sets,
                reps: reps,
                repRange: repRange,
                group: groupChoice(exercise: name, muscle: item.muscle, groups: groups),
                lowConfidence: item.lowConfidence || setsMisread || setsAndRepsLookSwapped(sets: sets, reps: reps),
                suggestedGroupName: item.muscle?.localizedName ?? ""
            )
        }
    }

    /// Where a scanned exercise lands, most certain signal first:
    /// 1. The exercise already exists in one of the groups → that group. Deterministic, and it's
    ///    what kept "Prensa" in Legs while the model said chest.
    /// 2. The model's muscle → the best of the user's groups for it (the same muscle in two
    ///    languages is resolved by `bestGroup`), or a new group named in the app's language.
    /// 3. Nothing: the user picks (and the import stays blocked until they do).
    ///
    /// Headings on the sheet are deliberately NOT used: in the on-device evaluation the model
    /// filled that field on every row — with "legs", "AMRAP", the exercise's own name or a
    /// section title — sending a whole PDF to Legs and creating groups named "AMRAP".
    @MainActor
    static func groupChoice(
        exercise: String,
        muscle: TargetMuscle?,
        groups: [MuscleEntry]
    ) -> ScannedExerciseDraft.GroupChoice? {
        let exerciseKey = NameMatching.fold(exercise)
        let holders = groups.filter { group in
            group.exercises.contains { NameMatching.fold($0.name) == exerciseKey }
        }
        if let holder = GroupRanking.mostInUse(holders) {
            return .existing(holder.id)
        }
        guard let muscle else { return nil }
        if let match = bestGroup(for: muscle, in: groups) {
            return .existing(match.id)
        }
        return .new(muscle.localizedName)
    }

    /// The user's group for `muscle`. Several candidates usually mean the same muscle in two
    /// languages ("Back" and "Espalda"): prefer a single-muscle group over a combined one
    /// ("Pecho" before "Pecho y tríceps"), then the one actually in use.
    @MainActor
    static func bestGroup(for muscle: TargetMuscle, in groups: [MuscleEntry]) -> MuscleEntry? {
        let candidates = groups.filter { TargetMuscle.muscles(inName: $0.name).contains(muscle) }
        return GroupRanking.mostInUse(candidates) { TargetMuscle.single(inName: $0.name) != nil }
    }

    /// A group with the same name, ignoring case and accents ("Gluteos" is "Glúteos").
    @MainActor
    private static func existingGroup(named name: String, in groups: [MuscleEntry]) -> MuscleEntry? {
        let key = NameMatching.fold(name)
        return groups.first { NameMatching.fold($0.name) == key }
    }

    // MARK: - Drafts → model

    struct Result: Equatable {
        var added = 0
        /// Rows whose exercise already existed in the target group — never duplicated.
        var skippedDuplicates = 0
        var createdGroups = 0
    }

    /// Loads reviewed drafts into the user's groups. Non-importable rows are ignored (the
    /// review screen doesn't let the user confirm with any).
    /// - Parameters:
    ///   - groups: ALL entries, not only gym ones — a "new" group whose name already exists
    ///     anywhere is reused instead of tripping the manager's duplicate-name check.
    ///   - createGroup: persists a new group with the given name (the view model routes it
    ///     through `MuscleEntryManager.addEntry`, the add screen's validation).
    @MainActor
    @discardableResult
    static func apply(
        _ drafts: [ScannedExerciseDraft],
        groups: [MuscleEntry],
        createGroup: (String) throws -> MuscleEntry
    ) rethrows -> Result {
        var result = Result()
        var known = groups

        for draft in drafts where draft.isImportable {
            let target: MuscleEntry
            switch draft.group {
            case .existing(let id):
                guard let match = known.first(where: { $0.id == id }) else { continue }
                target = match
            case .new(let rawName):
                let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                if let match = existingGroup(named: name, in: known) {
                    target = match
                } else {
                    target = try createGroup(name)
                    known.append(target)
                    result.createdGroups += 1
                }
            case nil:
                continue
            }

            let name = draft.trimmedName
            let key = NameMatching.fold(name)
            guard !target.exercises.contains(where: { NameMatching.fold($0.name) == key }) else {
                result.skippedDuplicates += 1
                continue
            }

            // A check-only group has no detail screen (`MuscleEntryRowView.canOpenGroup`),
            // so its new exercises would be unreachable. Loading exercises into it IS the
            // user asking for detail: open it up.
            if target.metric == .none {
                target.metric = .strength
            }

            let template = (draft.sets != nil || draft.reps != nil)
                ? [WorkoutSession(sets: draft.sets, reps: draft.reps, date: templateSessionDate)]
                : []
            target.exercises.append(Exercise(name: name, icon: target.icon, metric: .strength, sessions: template))
            result.added += 1
        }
        return result
    }
}
