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

    // MARK: - All Presets

    static let allPresets: [FilterPreset] = [
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Featured
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "tezza_vintage", name: "Vintage", displayName: "Vintage",
                     category: .featured, tier: .free, lutFileName: "tezza_vintage.cube", sortOrder: -500),
        FilterPreset(id: "tezza_mood", name: "Mood", displayName: "Mood",
                     category: .featured, tier: .free, lutFileName: "tezza_mood.cube", sortOrder: -400),
        FilterPreset(id: "tezza_lush", name: "Lush", displayName: "Lush",
                     category: .featured, tier: .free, lutFileName: "tezza_lush.cube", sortOrder: -300),
        FilterPreset(id: "tezza_dream", name: "Dream", displayName: "Dream",
                     category: .featured, tier: .free, lutFileName: "tezza_dream.cube", sortOrder: -200),
        FilterPreset(id: "tezza_golden", name: "Golden", displayName: "Golden",
                     category: .featured, tier: .free, lutFileName: "tezza_golden.cube", sortOrder: -100),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Clean Girl
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "cocoa", name: "Cocoa", displayName: "Cocoa",
                     category: .cleanGirl, tier: .free, lutFileName: "cocoa.cube", sortOrder: 0),
        FilterPreset(id: "butter", name: "Butter", displayName: "Butter",
                     category: .cleanGirl, tier: .free, lutFileName: "butter.cube", sortOrder: 1),
        FilterPreset(id: "goldie", name: "Goldie", displayName: "Goldie",
                     category: .cleanGirl, tier: .free, lutFileName: "goldie.cube", sortOrder: 2),
        FilterPreset(id: "latte", name: "Latte", displayName: "Latte",
                     category: .cleanGirl, tier: .free, lutFileName: "latte.cube", sortOrder: 3),
        FilterPreset(id: "dorado", name: "Dorado", displayName: "Dorado",
                     category: .cleanGirl, tier: .free, lutFileName: "dorado.cube", sortOrder: 4),
        FilterPreset(id: "canela", name: "Canela", displayName: "Canela",
                     category: .cleanGirl, tier: .free, lutFileName: "canela.cube", sortOrder: 5),
        FilterPreset(id: "glam", name: "Glam", displayName: "Glam",
                     category: .cleanGirl, tier: .free, lutFileName: "glam.cube", sortOrder: 6),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Soft
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "honey", name: "Honey", displayName: "Honey",
                     category: .soft, tier: .free, lutFileName: "honey.cube", sortOrder: 100),
        FilterPreset(id: "peach", name: "Peach", displayName: "Peach",
                     category: .soft, tier: .free, lutFileName: "peach.cube", sortOrder: 101),
        FilterPreset(id: "cloud", name: "Cloud", displayName: "Cloud",
                     category: .soft, tier: .free, lutFileName: "cloud.cube", sortOrder: 102),
        FilterPreset(id: "blush", name: "Blush", displayName: "Blush",
                     category: .soft, tier: .free, lutFileName: "blush.cube", sortOrder: 103),
        FilterPreset(id: "petalo", name: "Pétalo", displayName: "Pétalo",
                     category: .soft, tier: .free, lutFileName: "petalo.cube", sortOrder: 104),
        FilterPreset(id: "nube", name: "Nube", displayName: "Nube",
                     category: .soft, tier: .free, lutFileName: "nube.cube", sortOrder: 105),
        FilterPreset(id: "algodon", name: "Algodón", displayName: "Algodón",
                     category: .soft, tier: .free, lutFileName: "algodon.cube", sortOrder: 106),
        FilterPreset(id: "brisa", name: "Brisa", displayName: "Brisa",
                     category: .soft, tier: .free, lutFileName: "brisa.cube", sortOrder: 107),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Film
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "portra", name: "Portra", displayName: "Portra",
                     category: .film, tier: .free, lutFileName: "portra.cube", sortOrder: 200),
        FilterPreset(id: "fuji400", name: "Fuji 400", displayName: "Fuji 400",
                     category: .film, tier: .free, lutFileName: "fuji_400h.cube", sortOrder: 201),
        FilterPreset(id: "kodak", name: "Kodak", displayName: "Kodak",
                     category: .film, tier: .free, lutFileName: "kodak_gold.cube", sortOrder: 202),
        FilterPreset(id: "polaroid", name: "Polaroid", displayName: "Polaroid",
                     category: .film, tier: .free, lutFileName: "polaroid.cube", sortOrder: 203),
        FilterPreset(id: "super8", name: "Super8", displayName: "Super8",
                     category: .film, tier: .free, lutFileName: "super8.cube", sortOrder: 204),
        FilterPreset(id: "carbon", name: "Carbón", displayName: "Carbón",
                     category: .film, tier: .free, lutFileName: "carbon.cube", sortOrder: 205),
        FilterPreset(id: "seda", name: "Seda", displayName: "Seda",
                     category: .film, tier: .free, lutFileName: "seda.cube", sortOrder: 206),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Vintage
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "disposable", name: "Disposable", displayName: "Disposable",
                     category: .vintage, tier: .free, lutFileName: "disposable.cube", sortOrder: 300),
        FilterPreset(id: "throwback", name: "Throwback", displayName: "Throwback",
                     category: .vintage, tier: .free, lutFileName: "throwback.cube", sortOrder: 301),
        FilterPreset(id: "nostalgia", name: "Nostalgia", displayName: "Nostalgia",
                     category: .vintage, tier: .free, lutFileName: "nostalgia.cube", sortOrder: 302),
        FilterPreset(id: "vhs", name: "VHS", displayName: "VHS",
                     category: .vintage, tier: .free, lutFileName: "vhs.cube", sortOrder: 303),
    ]
}

// MARK: - Preset Category

enum PresetCategory: String, CaseIterable, Sendable {
    case featured
    case cleanGirl
    case soft
    case film
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .featured: return "Featured"
        case .cleanGirl: return "Clean Girl"
        case .soft: return "Soft"
        case .film: return "Film"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .featured: return "star.fill"
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
