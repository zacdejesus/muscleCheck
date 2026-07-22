//
//  AppColor.swift
//  MuscleCheck
//
//  Central color system. Views reference these semantic tokens instead of raw hues, so the
//  palette (and brand hue) can change in one place. The brand colour earns salience by being
//  scarce — use `.brand` for primary actions/brand moments, and the functional accents
//  (`.success`, `.streak`) to give state meaning, rather than painting everything brand.
//

import SwiftUI
import UIKit

extension Color {
    /// Primary brand colour (indigo). Primary actions, tint, active selection.
    /// (Aliases the `PrimaryButtonColor` asset; the auto-generated symbol is `.primaryButtonColor`.)
    static let brand = Color("PrimaryButtonColor")

    // `.success` (green, trained/checked) and `.streak` (warm amber, active streak) come
    // from the Success/Streak colorsets via Xcode's auto-generated asset symbols.

    // Text
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)

    // Surfaces (layered neutrals)
    static let surface = Color(uiColor: .systemGroupedBackground)
    static let surfaceElevated = Color(uiColor: .secondarySystemGroupedBackground)
}
