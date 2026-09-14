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

extension Color {
    /// Amber for TEXT and small indicators (warnings, "¿Eran 8 series de 14?"). The Streak
    /// amber reads at ~2:1 on white, so light mode uses a darker amber (#B45309, ≈5:1, WCAG
    /// AA). Dark mode keeps the Streak hue (#FBBF24), already ≈10:1 on the dark card.
    static let streakText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xFB / 255, green: 0xBF / 255, blue: 0x24 / 255, alpha: 1)
            : UIColor(red: 0xB4 / 255, green: 0x53 / 255, blue: 0x09 / 255, alpha: 1)
    })
}
