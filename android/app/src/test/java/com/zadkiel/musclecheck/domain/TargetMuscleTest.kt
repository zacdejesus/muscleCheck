package com.zadkiel.musclecheck.domain

import com.zadkiel.musclecheck.domain.model.ActivityCategory
import com.zadkiel.musclecheck.domain.model.MuscleEntry
import com.zadkiel.musclecheck.domain.model.NameMatching
import com.zadkiel.musclecheck.domain.model.TargetMuscle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/** Ported from the iOS `TargetMuscleTests` semantics (duplicate prevention half). */
class TargetMuscleTest {

    private fun entry(name: String, category: String = ActivityCategory.GYM.id) = MuscleEntry(
        id = "e-$name",
        name = name,
        isChecked = false,
        weekOfYear = 1,
        year = 2026,
        dateCreated = Instant.EPOCH,
        category = category,
        icon = "figure.strengthtraining.traditional",
    )

    // MARK: - Folding

    @Test
    fun `fold ignores case accents and punctuation`() {
        assertEquals("sentadilla bulgara", NameMatching.fold("Sentadilla búlgara"))
        assertEquals("sentadilla bulgara", NameMatching.fold("SENTADILLA  BULGARA!"))
        assertEquals("press banca", NameMatching.fold("  Press-banca  "))
    }

    @Test
    fun `fold keeps the letter when dropping its accent`() {
        assertEquals("gluteos", NameMatching.fold("Glúteos"))
        assertEquals("epaules", NameMatching.fold("Épaules"))
    }

    // MARK: - Name to muscle

    @Test
    fun `the same muscle in four languages resolves to one case`() {
        for (name in listOf("Chest", "Pecho", "Poitrine", "Petto")) {
            assertEquals(name, TargetMuscle.CHEST, TargetMuscle.single(name))
        }
    }

    @Test
    fun `combined names give every muscle and no single one`() {
        assertEquals(
            setOf(TargetMuscle.CHEST, TargetMuscle.TRICEPS),
            TargetMuscle.muscles("Pecho y tríceps"),
        )
        assertNull(TargetMuscle.single("Pecho y tríceps"))
    }

    @Test
    fun `free-form names name no muscle`() {
        assertTrue(TargetMuscle.muscles("Día 1").isEmpty())
        assertTrue(TargetMuscle.muscles("Patín").isEmpty())
        assertTrue(TargetMuscle.muscles("").isEmpty())
    }

    @Test
    fun `multi-word synonyms match as a whole phrase`() {
        assertEquals(TargetMuscle.FOREARMS, TargetMuscle.single("Avant bras"))
    }

    @Test
    fun `ambiguous dos counts only as the whole name`() {
        // French "dos" is back, but Spanish "dos" is the number two.
        assertEquals(TargetMuscle.BACK, TargetMuscle.single("Dos"))
        assertTrue(TargetMuscle.muscles("Día dos").isEmpty())
    }

    // MARK: - Repeated presets

    @Test
    fun `a preset repeats a muscle already added in another language`() {
        assertTrue(TargetMuscle.repeatsMuscle("Pecho", listOf(entry("Chest"))))
        assertTrue(TargetMuscle.repeatsMuscle("Espalda", listOf(entry("Back"), entry("Legs"))))
    }

    @Test
    fun `an identical name is not a language repeat`() {
        // That is the plain duplicate rule's job (countByName), not this one's.
        assertFalse(TargetMuscle.repeatsMuscle("Chest", listOf(entry("Chest"))))
        assertFalse(TargetMuscle.repeatsMuscle("Pecho", listOf(entry("PECHO"))))
    }

    @Test
    fun `different muscles and combined groups never repeat`() {
        assertFalse(TargetMuscle.repeatsMuscle("Pecho", listOf(entry("Back"))))
        assertFalse(TargetMuscle.repeatsMuscle("Pecho", listOf(entry("Pecho y tríceps"))))
        assertFalse(TargetMuscle.repeatsMuscle("Día 1", listOf(entry("Chest"))))
        assertFalse(TargetMuscle.repeatsMuscle("Pecho", emptyList()))
    }
}
