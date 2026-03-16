import Foundation

struct HSLAdjustment: Sendable, Equatable, Codable {
    var hue: Double = 0.0         // -0.5...0.5 (shift)
    var saturation: Double = 0.0  // -1.0...1.0
    var luminance: Double = 0.0   // -1.0...1.0

    var isDefault: Bool {
        hue == 0 && saturation == 0 && luminance == 0
    }
}

enum HSLColorRange: String, CaseIterable, Sendable, Codable {
    case red, orange, yellow, green, cyan, blue, purple, magenta

    var displayName: String {
        switch self {
        case .red: return "Rojo"
        case .orange: return "Naranja"
        case .yellow: return "Amarillo"
        case .green: return "Verde"
        case .cyan: return "Cian"
        case .blue: return "Azul"
        case .purple: return "Púrpura"
        case .magenta: return "Magenta"
        }
    }

    var displayColor: (Double, Double, Double) {
        switch self {
        case .red: return (0.0, 0.9, 0.9)
        case .orange: return (0.08, 0.9, 0.9)
        case .yellow: return (0.17, 0.9, 0.9)
        case .green: return (0.33, 0.8, 0.8)
        case .cyan: return (0.5, 0.8, 0.9)
        case .blue: return (0.67, 0.8, 0.9)
        case .purple: return (0.75, 0.7, 0.8)
        case .magenta: return (0.83, 0.8, 0.9)
        }
    }

    var hueCenter: Float {
        switch self {
        case .red: return 0.0
        case .orange: return 0.083
        case .yellow: return 0.167
        case .green: return 0.333
        case .cyan: return 0.5
        case .blue: return 0.667
        case .purple: return 0.75
        case .magenta: return 0.833
        }
    }
}

struct TextLayer: Sendable, Equatable, Codable, Identifiable {
    let id: String
    var text: String = "Texto"
    var style: TextStyle = .minimal
    var color: TextColor = .white
    var positionX: Double = 0.5
    var positionY: Double = 0.5
    var scale: Double = 1.0
    var rotation: Double = 0.0
}

enum TextStyle: String, CaseIterable, Sendable, Codable {
    case minimal
    case editorial
    case mono
    case analog

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .editorial: return "Editorial"
        case .mono: return "Mono"
        case .analog: return "Análogo"
        }
    }
}

enum TextColor: String, CaseIterable, Sendable, Codable {
    case white, black, cream, red

    var uiColor: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .white: return (1, 1, 1)
        case .black: return (0, 0, 0)
        case .cream: return (0.96, 0.93, 0.87)
        case .red: return (0.9, 0.2, 0.15)
        }
    }
}

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

    // Highlights & Shadows
    var highlights: Double = 0.0        // -1.0...1.0 (0 = neutral)
    var shadows: Double = 0.0           // -1.0...1.0 (0 = neutral)

    // Clarity (local contrast)
    var clarity: Double = 0.0           // 0.0...2.0 (0 = off)

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

    // Motion Blur
    var motionBlurIntensity: Double = 0.0    // 0.0...1.0
    var motionBlurAngle: Double = 0.0        // 0...360 degrees
    var motionBlurMaskEnabled: Bool = false
    var motionBlurMaskInverted: Bool = false   // false = blur IN painted area, true = blur OUT (outside)
    var motionBlurMask: Data? = nil           // PNG of grayscale mask

    // Film Blur
    var filmBlurIntensity: Double = 0.0     // 0.0...1.0

    // Low-Res
    var lowResIntensity: Double = 0.0       // 0.0...1.0

    // Color Tone (Split Toning)
    var shadowToneHue: Double = 0.0           // 0.0...1.0 (hue wheel)
    var shadowToneSaturation: Double = 0.0    // 0.0...1.0 (0 = off)
    var highlightToneHue: Double = 0.0        // 0.0...1.0
    var highlightToneSaturation: Double = 0.0 // 0.0...1.0

    // HSL
    var hslAdjustments: [String: HSLAdjustment] = [:]

    // Text
    var textLayers: [TextLayer] = []

    // Overlay
    var overlayId: String?
    var overlayIntensity: Double = 0.7   // 0.0...1.0

    // Crop
    var cropRect: CropRect?
    var cropAspectRatio: CropAspectRatio = .free
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

enum CropAspectRatio: String, CaseIterable, Sendable, Codable {
    case free
    case square
    case portrait4x5
    case story9x16
    case landscape16x9
    case classic4x3

    var displayName: String {
        switch self {
        case .free: return "Libre"
        case .square: return "1:1"
        case .portrait4x5: return "4:5"
        case .story9x16: return "9:16"
        case .landscape16x9: return "16:9"
        case .classic4x3: return "4:3"
        }
    }

    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .portrait4x5: return 4.0 / 5.0
        case .story9x16: return 9.0 / 16.0
        case .landscape16x9: return 16.0 / 9.0
        case .classic4x3: return 4.0 / 3.0
        }
    }
}
