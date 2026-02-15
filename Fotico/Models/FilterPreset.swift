import Foundation

struct FilterPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: PresetCategory
    let ciFilterName: String?
    let parameters: [FilterParameter]
    let defaultIntensity: Double

    static let allPresets: [FilterPreset] = [
        // Film Color Presets (E1-E5)
        FilterPreset(
            id: "fotico_1000",
            name: "E1",
            displayName: "E1",
            category: .film,
            ciFilterName: "CIPhotoEffectChrome",
            parameters: [
                FilterParameter(key: "temperature", value: 7000, minValue: 2000, maxValue: 10000)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_2000",
            name: "E2",
            displayName: "E2",
            category: .film,
            ciFilterName: "CIPhotoEffectProcess",
            parameters: [
                FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_3000",
            name: "E3",
            displayName: "E3",
            category: .film,
            ciFilterName: "CIPhotoEffectInstant",
            parameters: [
                FilterParameter(key: "vignette", value: 1.5, minValue: 0, maxValue: 3)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_4000",
            name: "E4",
            displayName: "E4",
            category: .film,
            ciFilterName: "CIPhotoEffectTransfer",
            parameters: [
                FilterParameter(key: "contrast", value: 1.3, minValue: 0.25, maxValue: 4)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_5000",
            name: "E5",
            displayName: "E5",
            category: .film,
            ciFilterName: "CIPhotoEffectFade",
            parameters: [
                FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000)
            ],
            defaultIntensity: 1.0
        ),

        // Color Grades (custom CIFilter chains)
        FilterPreset(
            id: "fotico_sunset",
            name: "Sunset",
            displayName: "Sunset",
            category: .film,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "temperature", value: 8500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 1.3, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.15, minValue: 0.25, maxValue: 4)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_cool",
            name: "Cool",
            displayName: "Cool",
            category: .film,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "temperature", value: 4500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.1, minValue: 0.25, maxValue: 4)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_vivid",
            name: "Vivid",
            displayName: "Vivid",
            category: .film,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "saturation", value: 1.5, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.2, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "vibrance", value: 0.5, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_faded",
            name: "Faded",
            displayName: "Faded",
            category: .vintage,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "saturation", value: 0.5, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.06, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_golden",
            name: "Golden",
            displayName: "Golden",
            category: .vintage,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "temperature", value: 8000, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.7, minValue: 0, maxValue: 2),
                FilterParameter(key: "vignette", value: 1.2, minValue: 0, maxValue: 3)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_soft",
            name: "Soft",
            displayName: "Soft",
            category: .film,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "contrast", value: 0.8, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "saturation", value: 0.9, minValue: 0, maxValue: 2),
                FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),

        // Black & White Presets
        FilterPreset(
            id: "fotico_bn1",
            name: "BW",
            displayName: "BW",
            category: .bw,
            ciFilterName: "CIPhotoEffectMono",
            parameters: [],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_bn2",
            name: "BW Noir",
            displayName: "Noir",
            category: .bw,
            ciFilterName: "CIPhotoEffectNoir",
            parameters: [],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_bn3",
            name: "BW Tonal",
            displayName: "Tonal",
            category: .bw,
            ciFilterName: "CIPhotoEffectTonal",
            parameters: [],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_silverplate",
            name: "Silver",
            displayName: "Silver",
            category: .bw,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "saturation", value: 0.0, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.4, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: -0.02, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),

        // Cinematic & Special
        FilterPreset(
            id: "fotico_cine",
            name: "Cine",
            displayName: "Cine",
            category: .cinematic,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "tealShadows", value: 0.6, minValue: 0, maxValue: 1),
                FilterParameter(key: "orangeHighlights", value: 0.5, minValue: 0, maxValue: 1),
                FilterParameter(key: "contrast", value: 1.2, minValue: 0.25, maxValue: 4)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_neon",
            name: "Neon",
            displayName: "Neon",
            category: .cinematic,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "saturation", value: 1.8, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.4, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "vibrance", value: 0.8, minValue: -1, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),
        FilterPreset(
            id: "fotico_retro",
            name: "Retro",
            displayName: "Retro",
            category: .vintage,
            ciFilterName: nil,
            parameters: [
                FilterParameter(key: "saturation", value: 0.6, minValue: 0, maxValue: 2),
                FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "grain", value: 0.4, minValue: 0, maxValue: 1)
            ],
            defaultIntensity: 1.0
        ),
    ]
}

enum PresetCategory: String, CaseIterable, Sendable {
    case film
    case bw
    case vintage
    case cinematic
    case custom

    nonisolated var displayName: String {
        switch self {
        case .film: return "Pelicula"
        case .bw: return "B&W"
        case .vintage: return "Vintage"
        case .cinematic: return "Cine"
        case .custom: return "Custom"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .film: return "film"
        case .bw: return "circle.lefthalf.filled"
        case .vintage: return "clock.arrow.circlepath"
        case .cinematic: return "theatermasks"
        case .custom: return "slider.horizontal.3"
        }
    }
}

struct FilterParameter: Sendable {
    let key: String
    let value: Double
    let minValue: Double
    let maxValue: Double
}
