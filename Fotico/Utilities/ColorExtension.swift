import SwiftUI

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
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Lumé Brand Colors — "Golden Hour" Palette
    static let lumePrimary = Color(hex: "#D4AF70")             // Lumé Gold — accent, CTAs, tints
    static let lumeSecondary = Color(hex: "#A68A4B")           // Antique Brass — labels, captions
    static let lumeAccent = Color(hex: "#F5E6C8")              // Warm Cream — hover, subtle fills
    static let lumeSuccess = Color(hex: "#34C759")             // System green
    static let lumeWarning = Color(hex: "#FF453A")             // System red
    static let lumeDark = Color(hex: "#0F0D08")                // Dark Roast — primary background
    static let lumeCardBg = Color(hex: "#1A1610")              // Warm dark card bg
    static let lumeSurface = Color(hex: "#2A2419")             // Warm dark surface
    static let lumeFilmGrain = Color(hex: "#3A322A")           // Warm sepia tint
    static let lumeLinen = Color(hex: "#FAF6EF")               // Linen — light backgrounds (future)
    static let lumeTextSecondary = Color(hex: "#8A7D6A")       // Warm gray for secondary text
    static let lumeDisabled = Color(hex: "#5A5045")            // Warm gray for disabled states
    static let lumeDivider = Color(hex: "#2F2820")             // Warm divider color
}
