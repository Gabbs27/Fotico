import Foundation

struct EditState: Sendable, Equatable, Codable {
    var selectedPresetId: String?
    var presetIntensity: Double = 1.0

    // Basic adjustments
    var brightness: Double = 0.0       // -1.0...1.0
    var contrast: Double = 1.0         // 0.25...4.0
    var saturation: Double = 1.0       // 0.0...2.0
    var exposure: Double = 0.0         // -2.0...2.0
    var sharpness: Double = 0.0        // 0.0...2.0
    var vibrance: Double = 0.0         // -1.0...1.0

    // Temperature & Tint
    var temperature: Double = 6500     // 2000...10000 Kelvin
    var tint: Double = 0.0             // -150...150

    // Effects
    var vignetteIntensity: Double = 0.0  // 0.0...2.0
    var vignetteRadius: Double = 1.0     // 0.0...2.0
    var grainIntensity: Double = 0.0     // 0.0...1.0
    var grainSize: Double = 0.5          // 0.1...1.0
    var bloomIntensity: Double = 0.0     // 0.0...2.0
    var bloomRadius: Double = 10.0       // 1.0...50.0
    var lightLeakIntensity: Double = 0.0 // 0.0...1.0
    var solarizeThreshold: Double = 0.0  // 0.0...1.0 (0 = off)
    var glitchIntensity: Double = 0.0    // 0.0...1.0
    var fisheyeIntensity: Double = 0.0   // 0.0...1.0
    var thresholdLevel: Double = 0.0     // 0.0...1.0 (0 = off)

    // Pro effects
    var dustIntensity: Double = 0.0             // 0.0...1.0
    var halationIntensity: Double = 0.0         // 0.0...1.0
    var chromaticAberrationIntensity: Double = 0.0 // 0.0...1.0
    var filmBurnIntensity: Double = 0.0         // 0.0...1.0
    var softDiffusionIntensity: Double = 0.0    // 0.0...1.0
    var letterboxIntensity: Double = 0.0        // 0.0...1.0

    // Overlay
    var overlayId: String?
    var overlayIntensity: Double = 0.7   // 0.0...1.0

    // Crop
    var cropRect: CropRect?
    var rotation: Double = 0.0           // degrees

    var isDefault: Bool {
        self == EditState()
    }

    mutating func reset() {
        self = EditState()
    }
}

struct CropRect: Sendable, Equatable, Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
