//
//  AppFont.swift
//  MuscleCheck
//
//  Central typography. To re-skin the whole app's type, change `family` (after bundling a
//  font) or `systemDesign` HERE — every view uses the `Font.app*` tokens below, so it's a
//  single switch. With both nil it falls back to the system font, so this layer is currently
//  a visual no-op; it just makes a future font swap a one-line change instead of 70+ edits.
//

import SwiftUI

enum AppFont {
    /// Bundled custom font family name (e.g. "Inter"). nil → system font.
    static let family: String? = nil

    /// System design used when `family` is nil (e.g. .rounded for a softer vibe). nil → default SF.
    static let systemDesign: Font.Design? = nil

    /// Dynamic Type-scaled font for a semantic text style.
    static func scaled(_ style: Font.TextStyle, _ size: CGFloat) -> Font {
        if let family {
            return .custom(family, size: size, relativeTo: style)
        }
        return .system(style, design: systemDesign ?? .default)
    }

    /// Fixed-size font (hero numbers etc.) that still honors the chosen family/design.
    static func fixed(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let family {
            return .custom(family, fixedSize: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: systemDesign ?? .default)
    }
}

extension Font {
    static var appLargeTitle: Font  { AppFont.scaled(.largeTitle, 34) }
    static var appTitle: Font       { AppFont.scaled(.title, 28) }
    static var appTitle2: Font      { AppFont.scaled(.title2, 22) }
    static var appTitle3: Font      { AppFont.scaled(.title3, 20) }
    static var appHeadline: Font    { AppFont.scaled(.headline, 17) }
    static var appBody: Font        { AppFont.scaled(.body, 17) }
    static var appCallout: Font     { AppFont.scaled(.callout, 16) }
    static var appSubheadline: Font { AppFont.scaled(.subheadline, 15) }
    static var appFootnote: Font    { AppFont.scaled(.footnote, 13) }
    static var appCaption: Font     { AppFont.scaled(.caption, 12) }
    static var appCaption2: Font    { AppFont.scaled(.caption2, 11) }
}
