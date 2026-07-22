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

/// Display formatting for session values. Single source for the metric labels shown
/// on home rows AND history rows, so separator/order/empty-handling can't drift.
/// Duration/distance are unit-invariant for v1 — minutes and km only, mirroring how
/// "kg"/"lbs" labels are literal.
enum SessionFormatting {

    /// "45 min" — whole minutes, storage is seconds.
    static func formatDuration(seconds: Int) -> String {
        "\(seconds / 60) min"
    }

    /// "5.2 km" — one decimal, storage is meters.
    static func formatDistance(meters: Double) -> String {
        String(format: "%.1f km", meters / 1000)
    }

    /// "20 kg" / "44 lbs" — whole numbers in the user's display unit; storage is kg.
    static func formatWeight(kg: Double) -> String {
        let unit = UserDefaultsManager.shared.weightUnit
        return String(format: "%.0f", unit.displayValue(fromKg: kg)) + " " + unit.displayLabel
    }

    /// The label for a set of session values under a given metric: "20 kg",
    /// "45 min", "5.2 km · 32 min". Nil when the metric logs nothing or no
    /// relevant value is present.
    static func label(metric: MetricType, weightKg: Double?, durationSeconds: Int?, distanceMeters: Double?) -> String? {
        switch metric {
        case .none:
            return nil
        case .strength:
            return weightKg.map(formatWeight)
        case .duration:
            return durationSeconds.map(formatDuration)
        case .distanceDuration:
            let parts = [
                distanceMeters.map(formatDistance),
                durationSeconds.map(formatDuration)
            ].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }
    }
}
