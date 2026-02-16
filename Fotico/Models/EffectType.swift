import Foundation

enum EffectType: String, CaseIterable, Sendable, Identifiable {
    case grain
    case lightLeak
    case bloom
    case vignette
    case solarize
    case glitch
    case fisheye
    case threshold

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .grain: return "Grano"
        case .lightLeak: return "Fuga de Luz"
        case .bloom: return "Bloom"
        case .vignette: return "Viñeta"
        case .solarize: return "Solarizar"
        case .glitch: return "Glitch"
        case .fisheye: return "Ojo de Pez"
        case .threshold: return "Umbral"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .grain: return "circle.dotted"
        case .lightLeak: return "sun.max.fill"
        case .bloom: return "sparkle"
        case .vignette: return "circle.dashed"
        case .solarize: return "sun.dust.fill"
        case .glitch: return "waveform.path.ecg"
        case .fisheye: return "eye.circle"
        case .threshold: return "square.split.diagonal"
        }
    }
}
