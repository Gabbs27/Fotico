import Foundation

enum EffectCategory: String, CaseIterable, Sendable, Identifiable {
    case film = "Film"
    case lens = "Lente"
    case stylize = "Estilo"
    case pro = "Pro"
    case blur = "Blur"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .film: return "Film"
        case .lens: return "Lente"
        case .stylize: return "Estilo"
        case .pro: return "Pro"
        case .blur: return "Blur"
        }
    }

    var icon: String {
        switch self {
        case .film: return "film"
        case .lens: return "camera.filters"
        case .stylize: return "paintbrush.pointed"
        case .pro: return "star.fill"
        case .blur: return "aqi.low"
        }
    }
}

enum EffectType: String, CaseIterable, Sendable, Identifiable {
    case grain
    case lightLeak
    case bloom
    case vignette
    case solarize
    case glitch
    case fisheye
    case threshold

    // Pro effects
    case dust
    case halation
    case chromaticAberration
    case filmBurn
    case softDiffusion
    case letterbox
    case motionBlur
    case filmBlur
    case lowRes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grain: return "Grano"
        case .lightLeak: return "Fuga de Luz"
        case .bloom: return "Bloom"
        case .vignette: return "Viñeta"
        case .solarize: return "Solarizar"
        case .glitch: return "Glitch"
        case .fisheye: return "Ojo de Pez"
        case .threshold: return "Umbral"
        case .dust: return "Polvo"
        case .halation: return "Halación"
        case .chromaticAberration: return "Aberración"
        case .filmBurn: return "Quemadura"
        case .softDiffusion: return "Difusión"
        case .letterbox: return "Cinemascope"
        case .motionBlur: return "Motion Blur"
        case .filmBlur: return "Film Blur"
        case .lowRes: return "Low-Res"
        }
    }

    var icon: String {
        switch self {
        case .grain: return "circle.dotted"
        case .lightLeak: return "sun.max.fill"
        case .bloom: return "sparkle"
        case .vignette: return "circle.dashed"
        case .solarize: return "sun.dust.fill"
        case .glitch: return "waveform.path.ecg"
        case .fisheye: return "eye.circle"
        case .threshold: return "square.split.diagonal"
        case .dust: return "aqi.medium"
        case .halation: return "sun.haze.fill"
        case .chromaticAberration: return "rainbow"
        case .filmBurn: return "flame.fill"
        case .softDiffusion: return "drop.fill"
        case .letterbox: return "rectangle.expand.vertical"
        case .motionBlur: return "lines.measurement.horizontal"
        case .filmBlur: return "aqi.medium"
        case .lowRes: return "square.resize.down"
        }
    }

    var category: EffectCategory {
        switch self {
        case .grain, .dust, .halation, .filmBurn: return .film
        case .bloom, .softDiffusion, .chromaticAberration, .fisheye: return .lens
        case .solarize, .glitch, .threshold, .letterbox, .lowRes: return .stylize
        case .vignette, .lightLeak: return .pro
        case .motionBlur, .filmBlur: return .blur
        }
    }
}
