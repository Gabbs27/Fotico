import Foundation

enum PresetTier: String, Codable, Sendable {
    case free
    case pro
}

struct FilterPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let category: PresetCategory
    let tier: PresetTier
    let lutFileName: String?        // e.g. "kodak_gold.cube" — nil means CIFilter chain
    let ciFilterName: String?
    let parameters: [FilterParameter]
    let defaultIntensity: Double
    let sortOrder: Int

    // Convenience init with defaults for backward compatibility
    init(id: String, name: String, category: PresetCategory,
         tier: PresetTier = .free, lutFileName: String? = nil,
         ciFilterName: String? = nil, parameters: [FilterParameter] = [],
         defaultIntensity: Double = 1.0, sortOrder: Int = 0) {
        self.id = id
        self.name = name
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
        FilterPreset(id: "ft_vintage", name: "Vintage",
                     category: .featured, lutFileName: "ft_vintage.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.45, minValue: 0, maxValue: 1),
                     ], sortOrder: -500),
        FilterPreset(id: "ft_mood", name: "Mood",
                     category: .featured, lutFileName: "ft_mood.cube", sortOrder: -400),
        FilterPreset(id: "ft_lush", name: "Lush",
                     category: .featured, lutFileName: "ft_lush.cube",
                     parameters: [
                         FilterParameter(key: "vignette", value: 0.8, minValue: 0, maxValue: 2),
                     ], sortOrder: -300),
        FilterPreset(id: "ft_dream", name: "Dream",
                     category: .featured, lutFileName: "ft_dream.cube",
                     parameters: [
                         FilterParameter(key: "bloom", value: 0.35, minValue: 0, maxValue: 1),
                         FilterParameter(key: "grain", value: 0.20, minValue: 0, maxValue: 1),
                     ], sortOrder: -200),
        FilterPreset(id: "ft_golden", name: "Golden",
                     category: .featured, lutFileName: "ft_golden.cube", sortOrder: -100),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Clean Girl
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "cocoa", name: "Cocoa",
                     category: .cleanGirl, lutFileName: "cocoa.cube", sortOrder: 0),
        FilterPreset(id: "butter", name: "Butter",
                     category: .cleanGirl, lutFileName: "butter.cube", sortOrder: 1),
        FilterPreset(id: "goldie", name: "Goldie",
                     category: .cleanGirl, lutFileName: "goldie.cube", sortOrder: 2),
        FilterPreset(id: "latte", name: "Latte",
                     category: .cleanGirl, lutFileName: "latte.cube", sortOrder: 3),
        FilterPreset(id: "dorado", name: "Dorado",
                     category: .cleanGirl, lutFileName: "dorado.cube", sortOrder: 4),
        FilterPreset(id: "canela", name: "Canela",
                     category: .cleanGirl, lutFileName: "canela.cube", sortOrder: 5),
        FilterPreset(id: "glam", name: "Glam",
                     category: .cleanGirl, lutFileName: "glam.cube", sortOrder: 6),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Soft
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "honey", name: "Honey",
                     category: .soft, lutFileName: "honey.cube", sortOrder: 100),
        FilterPreset(id: "peach", name: "Peach",
                     category: .soft, lutFileName: "peach.cube", sortOrder: 101),
        FilterPreset(id: "cloud", name: "Cloud",
                     category: .soft, lutFileName: "cloud.cube", sortOrder: 102),
        FilterPreset(id: "blush", name: "Blush",
                     category: .soft, lutFileName: "blush.cube", sortOrder: 103),
        FilterPreset(id: "petalo", name: "Pétalo",
                     category: .soft, lutFileName: "petalo.cube", sortOrder: 104),
        FilterPreset(id: "nube", name: "Nube",
                     category: .soft, lutFileName: "nube.cube", sortOrder: 105),
        FilterPreset(id: "algodon", name: "Algodón",
                     category: .soft, lutFileName: "algodon.cube", sortOrder: 106),
        FilterPreset(id: "brisa", name: "Brisa",
                     category: .soft, lutFileName: "brisa.cube", sortOrder: 107),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Film
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "portra", name: "Portra",
                     category: .film, lutFileName: "portra.cube", sortOrder: 200),
        FilterPreset(id: "fuji400", name: "Fuji 400",
                     category: .film, lutFileName: "fuji_400h.cube", sortOrder: 201),
        FilterPreset(id: "kodak", name: "Kodak",
                     category: .film, lutFileName: "kodak_gold.cube", sortOrder: 202),
        FilterPreset(id: "polaroid", name: "Polaroid",
                     category: .film, lutFileName: "polaroid.cube", sortOrder: 203),
        FilterPreset(id: "super8", name: "Super8",
                     category: .film, lutFileName: "super8.cube", sortOrder: 204),
        FilterPreset(id: "carbon", name: "Carbón",
                     category: .film, lutFileName: "carbon.cube", sortOrder: 205),
        FilterPreset(id: "seda", name: "Seda",
                     category: .film, lutFileName: "seda.cube", sortOrder: 206),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Vintage
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "disposable", name: "Disposable",
                     category: .vintage, lutFileName: "disposable.cube", sortOrder: 300),
        FilterPreset(id: "throwback", name: "Throwback",
                     category: .vintage, lutFileName: "throwback.cube", sortOrder: 301),
        FilterPreset(id: "nostalgia", name: "Nostalgia",
                     category: .vintage, lutFileName: "nostalgia.cube", sortOrder: 302),
        FilterPreset(id: "vhs", name: "VHS",
                     category: .vintage, lutFileName: "vhs.cube", sortOrder: 303),
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
