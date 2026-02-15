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

    // Fotico Brand Colors - Minimal Dark Theme
    static let foticoPrimary = Color.white                     // Clean white - active states, selections
    static let foticoSecondary = Color(hex: "#8E8E93")         // System gray - secondary elements
    static let foticoAccent = Color(hex: "#E8A849")            // Warm amber - subtle brand accent
    static let foticoSuccess = Color(hex: "#34C759")           // System green
    static let foticoWarning = Color(hex: "#FF453A")           // System red
    static let foticoDark = Color(hex: "#000000")              // Pure black background
    static let foticoCardBg = Color(hex: "#1C1C1E")            // System card bg
    static let foticoSurface = Color(hex: "#2C2C2E")           // System surface
    static let foticoFilmGrain = Color(hex: "#3A322A")         // Warm sepia tint
}
