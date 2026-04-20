import SwiftUI

// MARK: - Color tokens
// Source of truth: "WorldTracker Colorful / Vibrant & Elegant" design direction.
// Map: theme2.jsx V2 object.

extension Color {

    // MARK: Surfaces
    /// Warm off-white — primary app background (#F6F2EC)
    static let appPaper  = Color(hex: "#F6F2EC")
    /// Near-white secondary surface (#FFFDFA)
    static let appPaper2 = Color(hex: "#FFFDFA")
    /// Pure white card surface
    static let appCard   = Color.white

    // MARK: Ink / Text
    /// Primary text — navy-charcoal (#1A1B2E)
    static let appInk    = Color(hex: "#1A1B2E")
    /// Secondary text (#2F3150)
    static let appInk2   = Color(hex: "#2F3150")
    /// Tertiary / subdued text (#6A6E8A)
    static let appInk3   = Color(hex: "#6A6E8A")

    // MARK: Borders / Dividers
    /// Soft warm border / divider line (#E9E4DB)
    static let appLine   = Color(hex: "#E9E4DB")

    // MARK: Brand Palette
    /// Electric rose — primary CTA accent (#EC1763)
    static let appRose   = Color(hex: "#EC1763")
    /// Sky blue — primary navy-blue (#5568AF)
    static let appSky    = Color(hex: "#5568AF")
    /// Pale aqua — surface tint (#CEEAEE)
    static let appAqua   = Color(hex: "#CEEAEE")
    /// Lime — high-energy highlight (#CDD629)
    static let appLime   = Color(hex: "#CDD629")
    /// Blush — soft surface / badge background (#F8C9DD)
    static let appBlush  = Color(hex: "#F8C9DD")
    /// Sunset orange — warm energy (#F37826)
    static let appSunset = Color(hex: "#F37826")

    // MARK: Status
    /// Success green (#1E7F4E)
    static let appSuccess = Color(hex: "#1E7F4E")
}

// MARK: - Hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
