//
//  ActivityCategory.swift
//  MuscleCheck
//

import Foundation

enum ActivityCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case gym
    case running
    case yoga
    case pilates
    case calisthenics
    case cardio
    case stretching
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gym: return NSLocalizedString("category_gym", comment: "")
        case .yoga: return NSLocalizedString("category_yoga", comment: "")
        case .pilates: return NSLocalizedString("category_pilates", comment: "")
        case .calisthenics: return NSLocalizedString("category_calisthenics", comment: "")
        case .cardio: return NSLocalizedString("category_cardio", comment: "")
        case .stretching: return NSLocalizedString("category_stretching", comment: "")
        case .custom: return NSLocalizedString("category_custom", comment: "")
        case .running: return NSLocalizedString("category_running", comment: "")
        }
    }

    var defaultIcon: String {
        switch self {
        case .gym: return "figure.strengthtraining.traditional"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .calisthenics: return "figure.highintensity.intervaltraining"
        case .cardio: return "figure.run"
        case .stretching: return "figure.flexibility"
        case .custom: return "star.fill"
        case .running: return "figure.run"
        }
    }

    /// Whether activities in this category prompt for/show weight. Only gym does
    /// among the built-ins. Replaces the hardcoded `== .gym` checks scattered in
    /// WorkoutEligibility / MuscleEntryRowView / WeekDetailSection.
    var tracksWeight: Bool { self == .gym }

    var presetEntries: [(nameKey: String, icon: String)] {
        switch self {
        case .gym:
            return [
                ("group_chest", "figure.strengthtraining.traditional"),
                ("group_back", "figure.strengthtraining.traditional"),
                ("group_legs", "figure.strengthtraining.traditional"),
                ("group_shoulders", "figure.strengthtraining.traditional"),
                ("group_biceps", "figure.strengthtraining.traditional"),
                ("group_triceps", "figure.strengthtraining.traditional"),
                ("group_abdomen", "figure.core.training")
            ]
        case .yoga:
            return [
                ("yoga_vinyasa", "figure.yoga"),
                ("yoga_hatha", "figure.yoga"),
                ("yoga_ashtanga", "figure.yoga"),
                ("yoga_yin", "figure.yoga"),
                ("yoga_power", "figure.yoga")
            ]
        case .pilates:
            return [
                ("pilates_mat", "figure.pilates"),
                ("pilates_reformer", "figure.pilates"),
                ("pilates_core", "figure.pilates")
            ]
        case .calisthenics:
            return [
                ("calisthenics_upper", "figure.highintensity.intervaltraining"),
                ("calisthenics_lower", "figure.highintensity.intervaltraining"),
                ("calisthenics_full", "figure.highintensity.intervaltraining"),
                ("calisthenics_skills", "figure.highintensity.intervaltraining")
            ]
        case .cardio:
            return [
                ("cardio_cycling", "figure.outdoor.cycle"),
                ("cardio_swimming", "figure.pool.swim"),
                ("cardio_hiit", "figure.highintensity.intervaltraining"),
                ("cardio_walking", "figure.walk")
            ]
            
        case .running:
            return [
                ("cardio_running", "figure.run")
            ]
        case .stretching:
            return [
                ("stretching_upper", "figure.flexibility"),
                ("stretching_lower", "figure.flexibility"),
                ("stretching_full", "figure.flexibility")
            ]
        case .custom:
            return []
        }
    }

    /// All fitness-related SF Symbols for icon picker
    static let availableIcons: [String] = [
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
        "star.fill"
    ]

    /// Stable sort order matching allCases
    var sortOrder: Int {
        switch self {
        case .gym: return 0
        case .running: return 1
        case .yoga: return 2
        case .pilates: return 3
        case .calisthenics: return 4
        case .cardio: return 5
        case .stretching: return 6
        case .custom: return 7
        }
    }
}
