import Foundation

// Temporary — will be in FilterPreset.swift
enum PresetTier: String, Codable, Sendable {
    case free
    case pro
}

struct OverlayAsset: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: OverlayCategory
    let fileName: String
    let tier: PresetTier
    let sortOrder: Int

    static let allOverlays: [OverlayAsset] = [
        // Dust
        OverlayAsset(id: "dust_01", name: "Polvo 1", displayName: "Polvo 1", category: .dust, fileName: "dust_01", tier: .free, sortOrder: 0),
        OverlayAsset(id: "dust_02", name: "Polvo 2", displayName: "Polvo 2", category: .dust, fileName: "dust_02", tier: .pro, sortOrder: 1),
        OverlayAsset(id: "dust_03", name: "Polvo 3", displayName: "Polvo 3", category: .dust, fileName: "dust_03", tier: .pro, sortOrder: 2),
        // Light
        OverlayAsset(id: "light_01", name: "Luz 1", displayName: "Luz 1", category: .light, fileName: "light_01", tier: .free, sortOrder: 10),
        OverlayAsset(id: "light_02", name: "Luz 2", displayName: "Luz 2", category: .light, fileName: "light_02", tier: .pro, sortOrder: 11),
        OverlayAsset(id: "light_03", name: "Luz 3", displayName: "Luz 3", category: .light, fileName: "light_03", tier: .pro, sortOrder: 12),
        // Frames
        OverlayAsset(id: "frame_polaroid", name: "Polaroid", displayName: "Polaroid", category: .frames, fileName: "frame_polaroid", tier: .free, sortOrder: 20),
        OverlayAsset(id: "frame_35mm", name: "35mm", displayName: "35mm", category: .frames, fileName: "frame_35mm", tier: .pro, sortOrder: 21),
        OverlayAsset(id: "frame_super8", name: "Super8", displayName: "Super8", category: .frames, fileName: "frame_super8", tier: .pro, sortOrder: 22),
        // Paper
        OverlayAsset(id: "paper_01", name: "Papel 1", displayName: "Papel 1", category: .paper, fileName: "paper_01", tier: .free, sortOrder: 30),
        OverlayAsset(id: "paper_02", name: "Papel 2", displayName: "Papel 2", category: .paper, fileName: "paper_02", tier: .pro, sortOrder: 31),
        // Grain
        OverlayAsset(id: "grain_fine", name: "Fino", displayName: "Fino", category: .grain, fileName: "grain_fine", tier: .free, sortOrder: 40),
        OverlayAsset(id: "grain_heavy", name: "Grueso", displayName: "Grueso", category: .grain, fileName: "grain_heavy", tier: .pro, sortOrder: 41),
    ]
}

enum OverlayCategory: String, CaseIterable, Sendable {
    case dust
    case light
    case frames
    case paper
    case grain

    var displayName: String {
        switch self {
        case .dust: return "Polvo"
        case .light: return "Luz"
        case .frames: return "Marcos"
        case .paper: return "Papel"
        case .grain: return "Grano"
        }
    }

    var icon: String {
        switch self {
        case .dust: return "sparkles"
        case .light: return "sun.max.fill"
        case .frames: return "rectangle.inset.filled"
        case .paper: return "doc.fill"
        case .grain: return "circle.dotted"
        }
    }
}
