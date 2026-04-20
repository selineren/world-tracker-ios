import SwiftUI

// MARK: - Typography tokens
// Design direction: "WorldTracker Colorful / Vibrant & Elegant"
//   • Editorial / display — Fraunces (variable-weight optical-size serif, italic)
//   • UI / body           — Inter (clean geometric sans-serif)
//
// SETUP REQUIRED: Add Fraunces and Inter font files to the Xcode project target
// and declare them in Info.plist under "Fonts provided by application".
// Until then every style falls back gracefully to system fonts.

// MARK: - Font name constants
private enum FontName {
    static let fraunces       = "Fraunces"
    static let frauncesItalic = "Fraunces-Italic"
    static let inter          = "Inter"
    static let interSemiBold  = "Inter-SemiBold"
    static let interBold      = "Inter-Bold"
}

// MARK: - AppTypography
enum AppTypography {

    // MARK: Display / Editorial  (Fraunces serif, italic)
    // Used for: hero stat numbers, big screen titles

    /// Massive serif italic — hero stat numbers (≈90–180 pt in design)
    static let displayHero   = Font.custom(FontName.frauncesItalic, size: 90, relativeTo: .largeTitle)

    /// Large serif italic — section hero / big callout (≈44–64 pt)
    static let displayLarge  = Font.custom(FontName.frauncesItalic, size: 44, relativeTo: .largeTitle)

    /// Medium serif italic — card headings / country names (≈28–32 pt)
    static let displayMedium = Font.custom(FontName.frauncesItalic, size: 28, relativeTo: .title)

    /// Small serif italic — inline editorial accents (≈18–22 pt)
    static let displaySmall  = Font.custom(FontName.frauncesItalic, size: 19, relativeTo: .title2)

    // MARK: Screen Titles  (Fraunces serif, italic)

    /// Primary screen / section title (≈24–28 pt)
    static let screenTitle   = Font.custom(FontName.frauncesItalic, size: 26, relativeTo: .title)

    // MARK: Stat Numbers  (Fraunces serif, upright or italic)
    // Used for: continent counts, mini-tile values

    /// Large stat number (≈34 pt)
    static let statLarge     = Font.custom(FontName.fraunces, size: 34, relativeTo: .title)

    /// Small stat number (≈24 pt)
    static let statSmall     = Font.custom(FontName.fraunces, size: 24, relativeTo: .title2)

    // MARK: Body / UI  (Inter sans-serif)

    /// Standard body text (15 pt)
    static let body          = Font.custom(FontName.inter, size: 15, relativeTo: .body)

    /// Secondary / caption body (13 pt)
    static let bodySmall     = Font.custom(FontName.inter, size: 13, relativeTo: .subheadline)

    /// Tiny supporting caption (11 pt)
    static let caption       = Font.custom(FontName.inter, size: 11, relativeTo: .caption)

    // MARK: Section Label / Eyebrow
    // Per design: 10 pt, weight 600, letter-spacing 2.2, uppercase
    // Apply .tracking(2.2) and .textCase(.uppercase) alongside this font.
    static let eyebrow       = Font.custom(FontName.interSemiBold, size: 10, relativeTo: .caption2)

    // MARK: Labels / Buttons

    /// Medium-weight label (14 pt)
    static let label         = Font.custom(FontName.inter, size: 14, relativeTo: .callout)

    /// Semi-bold label (14 pt)
    static let labelSemiBold = Font.custom(FontName.interSemiBold, size: 14, relativeTo: .callout)

    /// Bold button / CTA label (15 pt)
    static let buttonLabel   = Font.custom(FontName.interBold, size: 15, relativeTo: .body)
}

// MARK: - Convenience modifiers

extension View {

    /// Applies the standard eyebrow / section-label style:
    /// 10 pt Inter SemiBold · uppercase · +2.2 tracking · `appInk3` foreground.
    func eyebrowStyle(color: Color = .appInk3) -> some View {
        self
            .font(AppTypography.eyebrow)
            .textCase(.uppercase)
            .tracking(2.2)
            .foregroundStyle(color)
    }
}
