//
//  WeightUnit.swift
//  MuscleCheck
//

import Foundation

/// User preference for weight display. Internally we ALWAYS store weights in kg.
/// Conversion happens at the display/input boundary in the UI.
enum WeightUnit: String, CaseIterable, Codable, Identifiable {
    case kg
    case lbs

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }

    /// Converts a value stored in kg to this unit for display.
    func displayValue(fromKg kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lbs: return kg * 2.20462
        }
    }

    /// Converts a value entered in this unit back to kg for storage.
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lbs: return value / 2.20462
        }
    }
}
