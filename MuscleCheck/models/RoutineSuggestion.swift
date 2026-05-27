//
//  RoutineSuggestion.swift
//  MuscleCheck
//
//  Version-agnostic, persistable representation of an AI day suggestion.
//  Mapped from the iOS-26-only `WorkoutSuggestion` (@Generable) so the rest of
//  the app (iOS 18 target) can hold and cache it without touching FoundationModels.
//

import Foundation

struct RoutineSuggestion: Codable, Equatable {

    struct Block: Codable, Equatable {
        /// Display name of one of the user's existing gym muscle groups.
        let groupName: String
        /// Example exercises for that group — read-only guidance, not tracked.
        let exercises: [String]
    }

    /// Short label for the day, e.g. "Push", "Pull", "Piernas".
    let focus: String
    /// Exactly two coherent muscle groups (validated when mapping from the model).
    let blocks: [Block]
    /// One short sentence on why this day was suggested.
    let rationale: String
}
