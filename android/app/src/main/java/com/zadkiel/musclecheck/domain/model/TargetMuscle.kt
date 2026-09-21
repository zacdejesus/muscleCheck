package com.zadkiel.musclecheck.domain.model

import java.text.Normalizer

/**
 * Port of the iOS `TargetMuscle`. A group's name is free text, so the app can't tell that
 * "Chest" and "Pecho" are the same muscle — presets are stored with the text of the language
 * active when they were added, so switching the phone's language leaves both. This gives names
 * a muscle identity WITHOUT touching the data model: a multilingual synonym table matched on
 * folded text.
 *
 * Only the duplicate-PREVENTION half of the iOS type is ported. There is no localized display
 * name (nothing on Android proposes new groups — that belongs to the routine scanner) and no
 * `GroupRanking` (no AI coach choosing among equivalent groups).
 */
enum class TargetMuscle {
    CHEST, BACK, SHOULDERS, BICEPS, TRICEPS, LEGS, GLUTES, CALVES, CORE, FOREARMS;

    /**
     * Folded words (ES/EN/FR/IT, singular and plural) that name this muscle. Entries with a
     * space are phrases matched as a whole ("avant bras").
     */
    private val synonyms: List<String>
        get() = when (this) {
            CHEST -> listOf(
                "chest", "pecho", "pechos", "pectoral", "pectorales", "pecs", "pec",
                "poitrine", "pectoraux", "petto", "pettorali", "pettorale",
            )
            BACK -> listOf(
                "back", "espalda", "dorsal", "dorsales", "lats", "dorsaux", "schiena", "dorsali",
            )
            SHOULDERS -> listOf(
                "shoulders", "shoulder", "hombros", "hombro", "deltoides", "deltoids", "delts",
                "epaules", "epaule", "spalle", "spalla", "deltoidi",
            )
            BICEPS -> listOf("biceps", "bicep", "bicipiti", "bicipite")
            TRICEPS -> listOf("triceps", "tricep", "tricipiti", "tricipite")
            LEGS -> listOf(
                "legs", "leg", "piernas", "pierna", "cuadriceps", "quads", "quadriceps",
                "isquiotibiales", "femorales", "hamstrings", "jambes", "jambe", "cuisses",
                "gambe", "gamba", "quadricipiti",
            )
            GLUTES -> listOf("glutes", "glute", "gluteos", "gluteo", "fessiers", "fessier", "glutei")
            CALVES -> listOf(
                "calves", "calf", "gemelos", "gemelo", "pantorrillas", "pantorrilla",
                "mollets", "mollet", "polpacci", "polpaccio",
            )
            CORE -> listOf(
                "core", "abdomen", "abs", "abdominales", "abdominal", "abdos", "abdominaux",
                "addome", "addominali", "oblicuos", "obliques",
            )
            FOREARMS -> listOf(
                "forearms", "forearm", "antebrazos", "antebrazo", "avant bras",
                "avambracci", "avambraccio",
            )
        }

    /**
     * Synonyms too ambiguous to match as a word inside a longer name: French "dos" (back) is
     * Spanish "two", so "Día dos" must not become a back day. Only the whole name counts.
     */
    private val wholeNameOnly: Set<String>
        get() = if (this == BACK) setOf("dos") else emptySet()

    companion object {

        /**
         * Muscles a group NAME refers to. Usually one; a combined group ("Pecho y tríceps")
         * gives several; free-form names ("Día 1", "Patín") give none.
         */
        fun muscles(inName: String): Set<TargetMuscle> {
            val normalized = NameMatching.fold(inName)
            if (normalized.isEmpty()) return emptySet()
            val words = normalized.split(' ').toSet()
            val padded = " $normalized "
            return TargetMuscle.entries.filter { muscle ->
                muscle.wholeNameOnly.contains(normalized) ||
                    muscle.synonyms.any { synonym ->
                        if (synonym.contains(' ')) padded.contains(" $synonym ") else words.contains(synonym)
                    }
            }.toSet()
        }

        /**
         * The muscle a name stands for on its own; null for free-form or combined names
         * ("Día 1", "Pecho y tríceps").
         */
        fun single(inName: String): TargetMuscle? = muscles(inName).singleOrNull()

        /**
         * Whether [ofName] repeats, under ANOTHER name, a muscle one of [groups] already covers —
         * the same preset in another language ("Pecho" when "Chest" exists). Identical names are
         * the regular duplicate rule's job; combined names never cover nor are covered.
         */
        fun repeatsMuscle(ofName: String, groups: List<MuscleEntry>): Boolean {
            val muscle = single(ofName) ?: return false
            val key = NameMatching.fold(ofName)
            return groups.any { NameMatching.fold(it.name) != key && single(it.name) == muscle }
        }
    }
}

/**
 * Text matching for names typed by people: case, accents and punctuation don't make two names
 * different ("Sentadilla búlgara" == "SENTADILLA BULGARA").
 */
object NameMatching {

    private val COMBINING_MARKS = "\\p{Mn}+".toRegex()

    /** Lowercased, accents removed, every run of non-letters collapsed into a single space. */
    fun fold(text: String): String {
        // Decompose first so an accent becomes its own combining mark and can be dropped
        // without taking the letter with it ("ú" -> "u" + mark -> "u").
        val decomposed = Normalizer.normalize(text.lowercase(), Normalizer.Form.NFD)
        return decomposed.replace(COMBINING_MARKS, "")
            .map { if (it.isLetter()) it else ' ' }
            .joinToString("")
            .split(' ')
            .filter { it.isNotEmpty() }
            .joinToString(" ")
    }
}
