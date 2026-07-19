//
//  MetricType.swift
//  MuscleCheck — Feature: per-exercise metrics
//
//  What a single exercise logs when checked, decided PER ENTRY (not per category —
//  the category only provides the default for new entries). Determines which fields
//  the session log modal shows. Inspired by the exercise-type model of gym trackers,
//  reduced to four cases to protect the "2-second" flow.
//

import Foundation

enum MetricType: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Check only — no session log.
    case none
    /// Weight + sets + reps (the original gym behavior).
    case strength
    /// Time only (plank, a yoga session).
    case duration
    /// Distance + time (running, cycling).
    case distanceDuration

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return NSLocalizedString("metric_type_none", comment: "")
        case .strength: return NSLocalizedString("metric_type_strength", comment: "")
        case .duration: return NSLocalizedString("metric_type_duration", comment: "")
        case .distanceDuration: return NSLocalizedString("metric_type_distance_duration", comment: "")
        }
    }

    /// Icon used where the metric is shown as a badge (e.g. category list rows).
    var icon: String {
        switch self {
        case .none: return "checkmark.circle"
        case .strength: return "dumbbell.fill"
        case .duration: return "timer"
        case .distanceDuration: return "point.topleft.down.to.point.bottomright.curvepath"
        }
    }
}

/// Display formatting for the non-weight metrics. Weight keeps its own path
/// (`MuscleEntry.formattedLastWeight` + WeightUnit); these are unit-invariant for
/// v1 — minutes and km only, mirroring how "kg"/"lbs" labels are literal.
enum SessionFormatting {

    /// "45 min" — whole minutes, storage is seconds.
    static func formatDuration(seconds: Int) -> String {
        "\(seconds / 60) min"
    }

    /// "5.2 km" — one decimal, storage is meters.
    static func formatDistance(meters: Double) -> String {
        String(format: "%.1f km", meters / 1000)
    }
}
