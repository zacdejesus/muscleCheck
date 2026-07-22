package com.zadkiel.musclecheck.domain.model

import android.content.Context

/**
 * Single point that turns a stored category string into display info, whether it came
 * from the built-in enum or a user-defined CustomCategory. Built-ins always win over a
 * custom with the same id; orphans (deleted custom category) degrade to the neutral
 * "Custom" label — never echo the raw UUID, never crash, never track weight.
 */
data class ResolvedCategory(
    val id: String,
    val displayName: String,
    val icon: String,
    val tracksWeight: Boolean,
    val isBuiltIn: Boolean,
)

object CategoryResolver {

    fun resolve(raw: String, custom: List<CustomCategory>, context: Context): ResolvedCategory {
        ActivityCategory.fromId(raw)?.let { builtIn ->
            return ResolvedCategory(
                id = raw,
                displayName = context.getString(builtIn.displayNameRes),
                icon = builtIn.defaultIcon,
                tracksWeight = builtIn.tracksWeight,
                isBuiltIn = true,
            )
        }
        custom.firstOrNull { it.id == raw }?.let { match ->
            return ResolvedCategory(
                id = raw,
                displayName = match.name,
                icon = match.icon,
                tracksWeight = match.tracksWeight,
                isBuiltIn = false,
            )
        }
        return ResolvedCategory(
            id = raw,
            displayName = context.getString(ActivityCategory.CUSTOM.displayNameRes),
            icon = ActivityCategory.CUSTOM.defaultIcon,
            tracksWeight = false,
            isBuiltIn = false,
        )
    }

    /** Stable sort key for grouping: built-ins keep their declared order, customs trail, ties break on id. */
    fun sortKey(raw: String): Pair<Int, String> =
        (ActivityCategory.fromId(raw)?.sortOrder ?: 99) to raw
}
