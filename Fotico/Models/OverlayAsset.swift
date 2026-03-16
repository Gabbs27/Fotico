import Foundation

struct OverlayAsset: Identifiable, Sendable {
    let id: String
    let displayName: String
    let category: OverlayCategory
    let fileName: String
    let tier: SubscriptionTier
    let sortOrder: Int

    static let allOverlays: [OverlayAsset] = [
        // Dust
        OverlayAsset(id: "dust_01", displayName: "Polvo 1", category: .dust, fileName: "dust_01", tier: .free, sortOrder: 0),
        OverlayAsset(id: "dust_02", displayName: "Polvo 2", category: .dust, fileName: "dust_02", tier: .pro, sortOrder: 1),
        OverlayAsset(id: "dust_03", displayName: "Polvo 3", category: .dust, fileName: "dust_03", tier: .pro, sortOrder: 2),
        // Light
        OverlayAsset(id: "light_01", displayName: "Luz 1", category: .light, fileName: "light_01", tier: .free, sortOrder: 10),
        OverlayAsset(id: "light_02", displayName: "Luz 2", category: .light, fileName: "light_02", tier: .pro, sortOrder: 11),
        OverlayAsset(id: "light_03", displayName: "Luz 3", category: .light, fileName: "light_03", tier: .pro, sortOrder: 12),
        // Frames
        OverlayAsset(id: "frame_polaroid", displayName: "Polaroid", category: .frames, fileName: "frame_polaroid", tier: .free, sortOrder: 20),
        OverlayAsset(id: "frame_35mm", displayName: "35mm", category: .frames, fileName: "frame_35mm", tier: .pro, sortOrder: 21),
        OverlayAsset(id: "frame_super8", displayName: "Super8", category: .frames, fileName: "frame_super8", tier: .pro, sortOrder: 22),
        // Paper
        OverlayAsset(id: "paper_01", displayName: "Papel 1", category: .paper, fileName: "paper_01", tier: .free, sortOrder: 30),
        OverlayAsset(id: "paper_02", displayName: "Papel 2", category: .paper, fileName: "paper_02", tier: .pro, sortOrder: 31),
        // Grain
        OverlayAsset(id: "grain_fine", displayName: "Fino", category: .grain, fileName: "grain_fine", tier: .free, sortOrder: 40),
        OverlayAsset(id: "grain_heavy", displayName: "Grueso", category: .grain, fileName: "grain_heavy", tier: .pro, sortOrder: 41),
        // Edges
        OverlayAsset(id: "edge_polaroid_border", displayName: "Polaroid", category: .edges, fileName: "edge_polaroid_border", tier: .free, sortOrder: 50),
        OverlayAsset(id: "edge_35mm_border", displayName: "35mm", category: .edges, fileName: "edge_35mm_border", tier: .free, sortOrder: 51),
        OverlayAsset(id: "edge_inset", displayName: "Inset", category: .edges, fileName: "edge_inset", tier: .free, sortOrder: 52),
        OverlayAsset(id: "edge_round", displayName: "Redondo", category: .edges, fileName: "edge_round", tier: .free, sortOrder: 53),
    ]
}

enum OverlayCategory: String, CaseIterable, Sendable, Identifiable {
    case dust
    case light
    case frames
    case paper
    case grain
    case edges

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dust: return "Polvo"
        case .light: return "Luz"
        case .frames: return "Marcos"
        case .paper: return "Papel"
        case .grain: return "Grano"
        case .edges: return "Bordes"
        }
    }

    var icon: String {
        switch self {
        case .dust: return "sparkles"
        case .light: return "sun.max.fill"
        case .frames: return "rectangle.inset.filled"
        case .paper: return "doc.fill"
        case .grain: return "circle.dotted"
        case .edges: return "rectangle.dashed"
        }
    }
}
