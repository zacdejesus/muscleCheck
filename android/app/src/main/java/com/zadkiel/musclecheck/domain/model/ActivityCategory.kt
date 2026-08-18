package com.zadkiel.musclecheck.domain.model

import androidx.annotation.StringRes
import com.zadkiel.musclecheck.R

/**
 * Built-in categories. `id` matches the iOS rawValue so entries created on either
 * platform resolve the same way. Icons are stored as the iOS SF Symbol name (a stable
 * string key) and mapped to Material icons at display time — see `AppIcons`.
 */
enum class ActivityCategory(
    val id: String,
    @StringRes val displayNameRes: Int,
    val defaultIcon: String,
) {
    GYM("gym", R.string.category_gym, "figure.strengthtraining.traditional"),
    RUNNING("running", R.string.category_running, "figure.run"),
    YOGA("yoga", R.string.category_yoga, "figure.yoga"),
    PILATES("pilates", R.string.category_pilates, "figure.pilates"),
    CALISTHENICS("calisthenics", R.string.category_calisthenics, "figure.highintensity.intervaltraining"),
    CARDIO("cardio", R.string.category_cardio, "figure.run"),
    STRETCHING("stretching", R.string.category_stretching, "figure.flexibility"),
    CUSTOM("custom", R.string.category_custom, "star.fill");

    /** Whether activities in this category prompt for/show weight. Only gym among built-ins. */
    @Deprecated("Superseded by defaultMetric (per-exercise metrics)", ReplaceWith("defaultMetric"))
    val tracksWeight: Boolean get() = this == GYM

    /**
     * Default metric for NEW entries in this category. The metric lives on each entry
     * ([MuscleEntry.metric]) and can be overridden at creation — this is only the
     * starting point, and the lazy fallback for pre-metric entries.
     */
    val defaultMetric: MetricType
        get() = when (this) {
            GYM -> MetricType.STRENGTH
            RUNNING -> MetricType.DISTANCE_DURATION
            CARDIO, YOGA, PILATES -> MetricType.DURATION
            CALISTHENICS, STRETCHING, CUSTOM -> MetricType.NONE
        }

    val sortOrder: Int get() = ordinal

    val presetEntries: List<PresetEntry>
        get() = when (this) {
            GYM -> listOf(
                PresetEntry(R.string.group_chest, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_back, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_legs, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_shoulders, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_biceps, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_triceps, "figure.strengthtraining.traditional"),
                PresetEntry(R.string.group_abdomen, "figure.core.training"),
            )
            YOGA -> listOf(
                PresetEntry(R.string.yoga_vinyasa, "figure.yoga"),
                PresetEntry(R.string.yoga_hatha, "figure.yoga"),
                PresetEntry(R.string.yoga_ashtanga, "figure.yoga"),
                PresetEntry(R.string.yoga_yin, "figure.yoga"),
                PresetEntry(R.string.yoga_power, "figure.yoga"),
            )
            PILATES -> listOf(
                PresetEntry(R.string.pilates_mat, "figure.pilates"),
                PresetEntry(R.string.pilates_reformer, "figure.pilates"),
                PresetEntry(R.string.pilates_core, "figure.pilates"),
            )
            CALISTHENICS -> listOf(
                PresetEntry(R.string.calisthenics_upper, "figure.highintensity.intervaltraining"),
                PresetEntry(R.string.calisthenics_lower, "figure.highintensity.intervaltraining"),
                PresetEntry(R.string.calisthenics_full, "figure.highintensity.intervaltraining"),
                PresetEntry(R.string.calisthenics_skills, "figure.highintensity.intervaltraining"),
            )
            CARDIO -> listOf(
                PresetEntry(R.string.cardio_cycling, "figure.outdoor.cycle"),
                PresetEntry(R.string.cardio_swimming, "figure.pool.swim"),
                PresetEntry(R.string.cardio_hiit, "figure.highintensity.intervaltraining"),
                PresetEntry(R.string.cardio_walking, "figure.walk"),
            )
            RUNNING -> listOf(
                PresetEntry(R.string.cardio_running, "figure.run"),
            )
            STRETCHING -> listOf(
                PresetEntry(R.string.stretching_upper, "figure.flexibility"),
                PresetEntry(R.string.stretching_lower, "figure.flexibility"),
                PresetEntry(R.string.stretching_full, "figure.flexibility"),
            )
            CUSTOM -> emptyList()
        }

    companion object {
        fun fromId(id: String): ActivityCategory? = entries.firstOrNull { it.id == id }

        /** All fitness-related icon keys for the icon picker. */
        val availableIcons: List<String> = listOf(
            "figure.strengthtraining.traditional",
            "figure.yoga",
            "figure.pilates",
            "figure.run",
            "figure.walk",
            "figure.outdoor.cycle",
            "figure.pool.swim",
            "figure.highintensity.intervaltraining",
            "figure.core.training",
            "figure.flexibility",
            "figure.cooldown",
            "figure.dance",
            "figure.martial.arts",
            "figure.boxing",
            "dumbbell.fill",
            "heart.fill",
            "flame.fill",
            "star.fill",
        )
    }
}

data class PresetEntry(@StringRes val nameRes: Int, val icon: String)
