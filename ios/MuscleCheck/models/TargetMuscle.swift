//
//  TargetMuscle.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  A group's name is free text, so the app can't tell that "Chest" and "Pecho" are the same
//  muscle — presets are stored with the text of the language active when they were added, so
//  switching the phone's language leaves both. This gives names a muscle identity WITHOUT
//  touching the data model: a multilingual synonym table matched on folded text. The scanner's
//  model picks one of these cases (a closed enum) instead of an index into the user's
//  duplicate-ridden list, and the code maps it to real groups.
//

import Foundation

enum TargetMuscle: String, CaseIterable, Sendable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case legs
    case glutes
    case calves
    case core
    case forearms

    /// Localized display name, used to propose a new group ("Glúteos") when none exists.
    /// Every one of them is also a synonym, so a proposed group is recognized next time.
    var localizedName: String {
        NSLocalizedString(nameKey, comment: "")
    }

    private var nameKey: String {
        switch self {
        case .chest: return "group_chest"
        case .back: return "group_back"
        case .shoulders: return "group_shoulders"
        case .biceps: return "group_biceps"
        case .triceps: return "group_triceps"
        case .legs: return "group_legs"
        case .glutes: return "group_glutes"
        case .calves: return "group_calves"
        case .core: return "group_abdomen"
        case .forearms: return "group_forearms"
        }
    }

    /// Folded words (ES/EN/FR/IT, singular and plural) that name this muscle. Entries with a
    /// space are phrases matched as a whole ("avant bras").
    private var synonyms: [String] {
        switch self {
        case .chest: return ["chest", "pecho", "pechos", "pectoral", "pectorales", "pecs", "pec", "poitrine", "pectoraux", "petto", "pettorali", "pettorale"]
        case .back: return ["back", "espalda", "dorsal", "dorsales", "lats", "dorsaux", "schiena", "dorsali"]
        case .shoulders: return ["shoulders", "shoulder", "hombros", "hombro", "deltoides", "deltoids", "delts", "epaules", "epaule", "spalle", "spalla", "deltoidi"]
        case .biceps: return ["biceps", "bicep", "bicipiti", "bicipite"]
        case .triceps: return ["triceps", "tricep", "tricipiti", "tricipite"]
        case .legs: return ["legs", "leg", "piernas", "pierna", "cuadriceps", "quads", "quadriceps", "isquiotibiales", "femorales", "hamstrings", "jambes", "jambe", "cuisses", "gambe", "gamba", "quadricipiti"]
        case .glutes: return ["glutes", "glute", "gluteos", "gluteo", "fessiers", "fessier", "glutei"]
        case .calves: return ["calves", "calf", "gemelos", "gemelo", "pantorrillas", "pantorrilla", "mollets", "mollet", "polpacci", "polpaccio"]
        case .core: return ["core", "abdomen", "abs", "abdominales", "abdominal", "abdos", "abdominaux", "addome", "addominali", "oblicuos", "obliques"]
        case .forearms: return ["forearms", "forearm", "antebrazos", "antebrazo", "avant bras", "avambracci", "avambraccio"]
        }
    }

    /// Synonyms too ambiguous to match as a word inside a longer name: French "dos" (back) is
    /// Spanish "two", so "Día dos" must not become a back day. Only the whole name counts.
    private var wholeNameOnly: Set<String> {
        self == .back ? ["dos"] : []
    }

    /// Muscles a group NAME refers to. Usually one; a combined group ("Pecho y tríceps") gives
    /// several; free-form names ("Día 1", "Patín") give none.
    static func muscles(inName name: String) -> Set<TargetMuscle> {
        let normalized = NameMatching.fold(name)
        guard !normalized.isEmpty else { return [] }
        let words = Set(normalized.split(separator: " ").map(String.init))
        let padded = " \(normalized) "
        return Set(allCases.filter { muscle in
            muscle.wholeNameOnly.contains(normalized)
                || muscle.synonyms.contains { synonym in
                    synonym.contains(" ") ? padded.contains(" \(synonym) ") : words.contains(synonym)
                }
        })
    }
}

/// Text matching for names typed by people and read off photos: case, accents and punctuation
/// don't make two names different ("Sentadilla búlgara" == "SENTADILLA BULGARA").
enum NameMatching {
    /// Lowercased, accents removed, every run of non-letters collapsed into a single space.
    static func fold(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).lowercased()
        let spaced = String(folded.unicodeScalars.map { CharacterSet.letters.contains($0) ? Character($0) : " " })
        return spaced.split(separator: " ").joined(separator: " ")
    }
}

extension TargetMuscle {
    /// The muscle a name stands for on its own; nil for free-form or combined names
    /// ("Día 1", "Pecho y tríceps").
    static func single(inName name: String) -> TargetMuscle? {
        let found = muscles(inName: name)
        return found.count == 1 ? found.first : nil
    }

    /// Whether `name` repeats, under ANOTHER name, a muscle one of `groups` already covers —
    /// the same preset in another language ("Pecho" when "Chest" exists). Identical names are
    /// the regular duplicate rule's job; combined names never cover nor are covered.
    static func repeatsMuscle(ofName name: String, in groups: [MuscleEntry]) -> Bool {
        guard let muscle = single(inName: name) else { return false }
        let key = NameMatching.fold(name)
        return groups.contains { NameMatching.fold($0.name) != key && single(inName: $0.name) == muscle }
    }
}

/// Choosing among groups that mean the same thing.
enum GroupRanking {
    /// The group actually in use: most recently trained, then more exercises. `isPreferred`
    /// ranks above both (e.g. single-muscle over combined groups). Ties keep the input order.
    static func mostInUse(_ groups: [MuscleEntry], isPreferred: (MuscleEntry) -> Bool = { _ in true }) -> MuscleEntry? {
        func rank(_ group: MuscleEntry) -> (Int, Date, Int) {
            (isPreferred(group) ? 1 : 0, group.sessions.map(\.date).max() ?? .distantPast, group.exercises.count)
        }
        return groups.max { rank($0) < rank($1) }
    }

    /// One group per muscle: where several groups name the same muscle (usually the same preset
    /// in two languages), keep only the one in use. Free-form and combined groups pass through.
    /// Input order is preserved.
    static func onePerMuscle(_ groups: [MuscleEntry]) -> [MuscleEntry] {
        var byMuscle: [TargetMuscle: [MuscleEntry]] = [:]
        for group in groups {
            if let muscle = TargetMuscle.single(inName: group.name) {
                byMuscle[muscle, default: []].append(group)
            }
        }
        let dropped = Set(byMuscle.values.flatMap { candidates -> [UUID] in
            guard candidates.count > 1, let keep = mostInUse(candidates) else { return [] }
            return candidates.filter { $0.id != keep.id }.map(\.id)
        })
        return groups.filter { !dropped.contains($0.id) }
    }
}
