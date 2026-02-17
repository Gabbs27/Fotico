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
        // Film Color Presets (E1-E5)
        FilterPreset(
            id: "fotico_1000", name: "E1", displayName: "E1",
            category: .film, tier: .free,
            ciFilterName: "CIPhotoEffectChrome",
            parameters: [FilterParameter(key: "temperature", value: 7000, minValue: 2000, maxValue: 10000)],
            sortOrder: 0
        ),
        FilterPreset(
            id: "fotico_2000", name: "E2", displayName: "E2",
            category: .film, tier: .free,
            ciFilterName: "CIPhotoEffectProcess",
            parameters: [FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1)],
            sortOrder: 1
        ),
        FilterPreset(
            id: "fotico_3000", name: "E3", displayName: "E3",
            category: .film, tier: .free,
            ciFilterName: "CIPhotoEffectInstant",
            parameters: [FilterParameter(key: "vignette", value: 1.5, minValue: 0, maxValue: 3)],
            sortOrder: 2
        ),
        FilterPreset(
            id: "fotico_4000", name: "E4", displayName: "E4",
            category: .film, tier: .free,
            ciFilterName: "CIPhotoEffectTransfer",
            parameters: [FilterParameter(key: "contrast", value: 1.3, minValue: 0.25, maxValue: 4)],
            sortOrder: 3
        ),
        FilterPreset(
            id: "fotico_5000", name: "E5", displayName: "E5",
            category: .film, tier: .free,
            ciFilterName: "CIPhotoEffectFade",
            parameters: [FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000)],
            sortOrder: 4
        ),

        // Color Grades (custom CIFilter chains)
        FilterPreset(
            id: "fotico_sunset", name: "Sunset", displayName: "Sunset",
            category: .warm, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 8500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 1.3, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.15, minValue: 0.25, maxValue: 4)
            ],
            sortOrder: 10
        ),
        FilterPreset(
            id: "fotico_cool", name: "Cool", displayName: "Cool",
            category: .cool, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 4500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.1, minValue: 0.25, maxValue: 4)
            ],
            sortOrder: 11
        ),
        FilterPreset(
            id: "fotico_vivid", name: "Vivid", displayName: "Vivid",
            category: .warm, tier: .free,
            parameters: [
                FilterParameter(key: "saturation", value: 1.5, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.2, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "vibrance", value: 0.5, minValue: -1, maxValue: 1)
            ],
            sortOrder: 12
        ),
        FilterPreset(
            id: "fotico_faded", name: "Faded", displayName: "Faded",
            category: .vintage, tier: .free,
            parameters: [
                FilterParameter(key: "saturation", value: 0.5, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: 0.06, minValue: -1, maxValue: 1)
            ],
            sortOrder: 13
        ),
        FilterPreset(
            id: "fotico_golden", name: "Golden", displayName: "Golden",
            category: .warm, tier: .free,
            parameters: [
                FilterParameter(key: "temperature", value: 8000, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "saturation", value: 0.7, minValue: 0, maxValue: 2),
                FilterParameter(key: "vignette", value: 1.2, minValue: 0, maxValue: 3)
            ],
            sortOrder: 14
        ),
        FilterPreset(
            id: "fotico_soft", name: "Soft", displayName: "Soft",
            category: .soft, tier: .free,
            parameters: [
                FilterParameter(key: "contrast", value: 0.8, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "saturation", value: 0.9, minValue: 0, maxValue: 2),
                FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1)
            ],
            sortOrder: 15
        ),

        // Black & White
        FilterPreset(
            id: "fotico_bn1", name: "BW", displayName: "BW",
            category: .bw, tier: .free,
            ciFilterName: "CIPhotoEffectMono",
            sortOrder: 20
        ),
        FilterPreset(
            id: "fotico_bn2", name: "BW Noir", displayName: "Noir",
            category: .bw, tier: .free,
            ciFilterName: "CIPhotoEffectNoir",
            sortOrder: 21
        ),
        FilterPreset(
            id: "fotico_bn3", name: "BW Tonal", displayName: "Tonal",
            category: .bw, tier: .free,
            ciFilterName: "CIPhotoEffectTonal",
            sortOrder: 22
        ),
        FilterPreset(
            id: "fotico_silverplate", name: "Silver", displayName: "Silver",
            category: .bw, tier: .free,
            parameters: [
                FilterParameter(key: "saturation", value: 0.0, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.4, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "brightness", value: -0.02, minValue: -1, maxValue: 1)
            ],
            sortOrder: 23
        ),

        // Cinematic & Special
        FilterPreset(
            id: "fotico_cine", name: "Cine", displayName: "Cine",
            category: .cinematic, tier: .free,
            parameters: [
                FilterParameter(key: "tealShadows", value: 0.6, minValue: 0, maxValue: 1),
                FilterParameter(key: "orangeHighlights", value: 0.5, minValue: 0, maxValue: 1),
                FilterParameter(key: "contrast", value: 1.2, minValue: 0.25, maxValue: 4)
            ],
            sortOrder: 30
        ),
        FilterPreset(
            id: "fotico_neon", name: "Neon", displayName: "Neon",
            category: .cinematic, tier: .free,
            parameters: [
                FilterParameter(key: "saturation", value: 1.8, minValue: 0, maxValue: 2),
                FilterParameter(key: "contrast", value: 1.4, minValue: 0.25, maxValue: 4),
                FilterParameter(key: "vibrance", value: 0.8, minValue: -1, maxValue: 1)
            ],
            sortOrder: 31
        ),
        FilterPreset(
            id: "fotico_retro", name: "Retro", displayName: "Retro",
            category: .vintage, tier: .free,
            parameters: [
                FilterParameter(key: "saturation", value: 0.6, minValue: 0, maxValue: 2),
                FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000),
                FilterParameter(key: "grain", value: 0.4, minValue: 0, maxValue: 1)
            ],
            sortOrder: 32
        ),
    ]

    // MARK: - Pro Presets (LUT-based)

    static let proPresets: [FilterPreset] = [
        // Cálidos (Warm)
        FilterPreset(id: "pro_dorado", name: "Dorado", displayName: "Dorado",
                     category: .warm, tier: .free, lutFileName: "dorado.cube", sortOrder: 100),
        FilterPreset(id: "pro_miel", name: "Miel", displayName: "Miel",
                     category: .warm, tier: .free, lutFileName: "miel.cube", sortOrder: 101),
        FilterPreset(id: "pro_canela", name: "Canela", displayName: "Canela",
                     category: .warm, tier: .free, lutFileName: "canela.cube", sortOrder: 102),
        FilterPreset(id: "pro_atardecer", name: "Atardecer", displayName: "Atardecer",
                     category: .warm, tier: .free, lutFileName: "atardecer.cube", sortOrder: 103),

        // Fríos (Cool)
        FilterPreset(id: "pro_oceano", name: "Océano", displayName: "Océano",
                     category: .cool, tier: .free, lutFileName: "oceano.cube", sortOrder: 200),
        FilterPreset(id: "pro_niebla", name: "Niebla", displayName: "Niebla",
                     category: .cool, tier: .free, lutFileName: "niebla.cube", sortOrder: 201),
        FilterPreset(id: "pro_invierno", name: "Invierno", displayName: "Invierno",
                     category: .cool, tier: .free, lutFileName: "invierno.cube", sortOrder: 202),

        // Cine
        FilterPreset(id: "pro_noche", name: "Noche", displayName: "Noche",
                     category: .cinematic, tier: .free, lutFileName: "noche.cube", sortOrder: 300),
        FilterPreset(id: "pro_drama", name: "Drama", displayName: "Drama",
                     category: .cinematic, tier: .free, lutFileName: "drama.cube", sortOrder: 301),
        FilterPreset(id: "pro_teal_orange", name: "Teal&Orange", displayName: "Teal&Orange",
                     category: .cinematic, tier: .free, lutFileName: "teal_orange.cube", sortOrder: 302),

        // Suaves (Soft/Pastel)
        FilterPreset(id: "pro_petalo", name: "Pétalo", displayName: "Pétalo",
                     category: .soft, tier: .free, lutFileName: "petalo.cube", sortOrder: 400),
        FilterPreset(id: "pro_nube", name: "Nube", displayName: "Nube",
                     category: .soft, tier: .free, lutFileName: "nube.cube", sortOrder: 401),
        FilterPreset(id: "pro_algodon", name: "Algodón", displayName: "Algodón",
                     category: .soft, tier: .free, lutFileName: "algodon.cube", sortOrder: 402),
        FilterPreset(id: "pro_brisa", name: "Brisa", displayName: "Brisa",
                     category: .soft, tier: .free, lutFileName: "brisa.cube", sortOrder: 403),

        // Película (Film emulation)
        FilterPreset(id: "pro_kodak", name: "Kodak", displayName: "Kodak",
                     category: .film, tier: .free, lutFileName: "kodak_gold.cube", sortOrder: 500),
        FilterPreset(id: "pro_fuji", name: "Fuji", displayName: "Fuji",
                     category: .film, tier: .free, lutFileName: "fuji_400h.cube", sortOrder: 501),
        FilterPreset(id: "pro_polaroid", name: "Polaroid", displayName: "Polaroid",
                     category: .film, tier: .free, lutFileName: "polaroid.cube", sortOrder: 502),
        FilterPreset(id: "pro_super8", name: "Super8", displayName: "Super8",
                     category: .film, tier: .free, lutFileName: "super8.cube", sortOrder: 503),

        // Editorial
        FilterPreset(id: "pro_revista", name: "Revista", displayName: "Revista",
                     category: .editorial, tier: .free, lutFileName: "revista.cube", sortOrder: 600),
        FilterPreset(id: "pro_portada", name: "Portada", displayName: "Portada",
                     category: .editorial, tier: .free, lutFileName: "portada.cube", sortOrder: 601),
        FilterPreset(id: "pro_glam", name: "Glam", displayName: "Glam",
                     category: .editorial, tier: .free, lutFileName: "glam.cube", sortOrder: 602),
        FilterPreset(id: "pro_mate", name: "Mate", displayName: "Mate",
                     category: .editorial, tier: .free, lutFileName: "mate.cube", sortOrder: 603),

        // Vintage
        FilterPreset(id: "pro_nostalgia", name: "Nostalgia", displayName: "Nostalgia",
                     category: .vintage, tier: .free, lutFileName: "nostalgia.cube", sortOrder: 700),
        FilterPreset(id: "pro_sepia", name: "Sepia", displayName: "Sepia",
                     category: .vintage, tier: .free, lutFileName: "sepia.cube", sortOrder: 701),
        FilterPreset(id: "pro_disco", name: "Disco", displayName: "Disco",
                     category: .vintage, tier: .free, lutFileName: "disco.cube", sortOrder: 702),
        FilterPreset(id: "pro_vhs", name: "VHS", displayName: "VHS",
                     category: .vintage, tier: .free, lutFileName: "vhs.cube", sortOrder: 703),

        // B&W
        FilterPreset(id: "pro_carbon", name: "Carbón", displayName: "Carbón",
                     category: .bw, tier: .free, lutFileName: "carbon.cube", sortOrder: 800),
        FilterPreset(id: "pro_seda", name: "Seda", displayName: "Seda",
                     category: .bw, tier: .free, lutFileName: "seda.cube", sortOrder: 801),
    ]
}

// MARK: - Preset Category

enum PresetCategory: String, CaseIterable, Sendable {
    case film
    case warm
    case cool
    case bw
    case cinematic
    case soft
    case editorial
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .film: return "Película"
        case .warm: return "Cálidos"
        case .cool: return "Fríos"
        case .bw: return "B&W"
        case .cinematic: return "Cine"
        case .soft: return "Suaves"
        case .editorial: return "Editorial"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .film: return "film"
        case .warm: return "sun.max.fill"
        case .cool: return "snowflake"
        case .bw: return "circle.lefthalf.filled"
        case .cinematic: return "theatermasks"
        case .soft: return "cloud.fill"
        case .editorial: return "newspaper.fill"
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
