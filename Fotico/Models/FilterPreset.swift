import Foundation

enum PresetTier: String, Codable, Sendable {
    case free
    case pro
}

struct FilterPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: PresetCategory
    let tier: PresetTier
    let lutFileName: String?        // e.g. "kodak_gold.cube" — nil means CIFilter chain
    let ciFilterName: String?
    let parameters: [FilterParameter]
    let defaultIntensity: Double
    let sortOrder: Int

    // Convenience init with defaults for backward compatibility
    init(id: String, name: String, displayName: String, category: PresetCategory,
         tier: PresetTier = .free, lutFileName: String? = nil,
         ciFilterName: String? = nil, parameters: [FilterParameter] = [],
         defaultIntensity: Double = 1.0, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category
        self.tier = tier
        self.lutFileName = lutFileName
        self.ciFilterName = ciFilterName
        self.parameters = parameters
        self.defaultIntensity = defaultIntensity
        self.sortOrder = sortOrder
    }

    // MARK: - All Presets (Free + Pro)

    static let allPresets: [FilterPreset] = freePresets + proPresets

    // MARK: - Free Presets (CIFilter-based)

    static let freePresets: [FilterPreset] = [
        // MARK: Clean Girl
        FilterPreset(
            id: "cocoa", name: "Cocoa", displayName: "Cocoa",
            category: .cleanGirl, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7800, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.95, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.05, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.03, minValue: -1, maxValue: 1),
            ],
            sortOrder: 0
        ),
        FilterPreset(
            id: "butter", name: "Butter", displayName: "Butter",
            category: .cleanGirl, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 1.1, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.9, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
            ],
            sortOrder: 1
        ),
        FilterPreset(
            id: "goldie", name: "Goldie", displayName: "Goldie",
            category: .cleanGirl, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 8200, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 1.05, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.1, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "vignette", value: 0.5, minValue: 0, maxValue: 3),
            ],
            sortOrder: 2
        ),
        FilterPreset(
            id: "latte", name: "Latte", displayName: "Latte",
            category: .cleanGirl, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7200, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.8, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.95, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1),
            ],
            sortOrder: 3
        ),

        // MARK: Soft
        FilterPreset(
            id: "honey", name: "Honey", displayName: "Honey",
            category: .soft, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7600, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.06, minValue: -1, maxValue: 1),
            ],
            sortOrder: 100
        ),
        FilterPreset(
            id: "peach", name: "Peach", displayName: "Peach",
            category: .soft, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7000, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.9, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.88, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
            ],
            sortOrder: 101
        ),
        FilterPreset(
            id: "cloud", name: "Cloud", displayName: "Cloud",
            category: .soft, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 6800, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.78, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.07, minValue: -1, maxValue: 1),
            ],
            sortOrder: 102
        ),
        FilterPreset(
            id: "blush", name: "Blush", displayName: "Blush",
            category: .soft, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 6500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 1.05, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1),
            ],
            sortOrder: 103
        ),

        // MARK: Vintage
        FilterPreset(
            id: "disposable", name: "Disposable", displayName: "Disposable",
            category: .vintage, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 8000, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.7, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.15, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "grain", value: 0.35, minValue: 0, maxValue: 1),
                FilterParameter(key: "vignette", value: 1.5, minValue: 0, maxValue: 3),
            ],
            sortOrder: 300
        ),
        FilterPreset(
            id: "throwback", name: "Throwback", displayName: "Throwback",
            category: .vintage, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 7800, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.55, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.9, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
                FilterParameter(key: "grain", value: 0.2, minValue: 0, maxValue: 1),
            ],
            sortOrder: 301
        ),
    ]

    // MARK: - Pro Presets (LUT-based)

    static let proPresets: [FilterPreset] = [
        // MARK: Clean Girl (LUT)
        FilterPreset(id: "pro_dorado", name: "Dorado", displayName: "Dorado",
                     category: .cleanGirl, tier: .free, lutFileName: "dorado.cube", sortOrder: 4),
        FilterPreset(id: "pro_canela", name: "Canela", displayName: "Canela",
                     category: .cleanGirl, tier: .free, lutFileName: "canela.cube", sortOrder: 5),
        FilterPreset(id: "pro_glam", name: "Glam", displayName: "Glam",
                     category: .cleanGirl, tier: .free, lutFileName: "glam.cube", sortOrder: 6),

        // MARK: Soft (LUT)
        FilterPreset(id: "pro_petalo", name: "Pétalo", displayName: "Pétalo",
                     category: .soft, tier: .free, lutFileName: "petalo.cube", sortOrder: 104),
        FilterPreset(id: "pro_nube", name: "Nube", displayName: "Nube",
                     category: .soft, tier: .free, lutFileName: "nube.cube", sortOrder: 105),
        FilterPreset(id: "pro_algodon", name: "Algodón", displayName: "Algodón",
                     category: .soft, tier: .free, lutFileName: "algodon.cube", sortOrder: 106),
        FilterPreset(id: "pro_brisa", name: "Brisa", displayName: "Brisa",
                     category: .soft, tier: .free, lutFileName: "brisa.cube", sortOrder: 107),

        // MARK: Film (LUT)
        FilterPreset(id: "pro_portra", name: "Portra", displayName: "Portra",
                     category: .film, tier: .free, lutFileName: "portra.cube", sortOrder: 200),
        FilterPreset(id: "pro_fuji", name: "Fuji 400", displayName: "Fuji 400",
                     category: .film, tier: .free, lutFileName: "fuji_400h.cube", sortOrder: 201),
        FilterPreset(id: "pro_kodak", name: "Kodak", displayName: "Kodak",
                     category: .film, tier: .free, lutFileName: "kodak_gold.cube", sortOrder: 202),
        FilterPreset(id: "pro_polaroid", name: "Polaroid", displayName: "Polaroid",
                     category: .film, tier: .free, lutFileName: "polaroid.cube", sortOrder: 203),
        FilterPreset(id: "pro_super8", name: "Super8", displayName: "Super8",
                     category: .film, tier: .free, lutFileName: "super8.cube", sortOrder: 204),
        FilterPreset(id: "pro_carbon", name: "Carbón", displayName: "Carbón",
                     category: .film, tier: .free, lutFileName: "carbon.cube", sortOrder: 205),
        FilterPreset(id: "pro_seda", name: "Seda", displayName: "Seda",
                     category: .film, tier: .free, lutFileName: "seda.cube", sortOrder: 206),

        // MARK: Vintage (LUT)
        FilterPreset(id: "pro_nostalgia", name: "Nostalgia", displayName: "Nostalgia",
                     category: .vintage, tier: .free, lutFileName: "nostalgia.cube", sortOrder: 302),
        FilterPreset(id: "pro_vhs", name: "VHS", displayName: "VHS",
                     category: .vintage, tier: .free, lutFileName: "vhs.cube", sortOrder: 303),
    ]
}

// MARK: - Preset Category

enum PresetCategory: String, CaseIterable, Sendable {
    case cleanGirl
    case soft
    case film
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .cleanGirl: return "Clean Girl"
        case .soft: return "Soft"
        case .film: return "Film"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .cleanGirl: return "sparkles"
        case .soft: return "cloud.fill"
        case .film: return "film"
        case .vintage: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Filter Parameter

struct FilterParameter: Sendable {
    let key: String
    let value: Double
    let minValue: Double
    let maxValue: Double
}
