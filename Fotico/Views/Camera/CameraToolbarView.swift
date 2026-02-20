import SwiftUI

enum CameraToolbarTab: String, CaseIterable, Sendable {
    case grid, texture, fx, flash

    var icon: String {
        switch self {
        case .grid: return "grid"
        case .texture: return "line.3.horizontal"
        case .fx: return "wand.and.stars"
        case .flash: return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .grid: return "Rejilla"
        case .texture: return "Textura"
        case .fx: return "FX"
        case .flash: return "Flash"
        }
    }
}

enum GridMode: String, Sendable {
    case off, thirds, center, golden
}

enum GrainLevel: String, Sendable {
    case off, light, medium, heavy

    var intensity: Double {
        switch self {
        case .off: return 0
        case .light: return 0.02
        case .medium: return 0.04
        case .heavy: return 0.08
        }
    }
}

struct CameraToolbarView: View {
    @Binding var selectedTab: CameraToolbarTab?
    @Binding var gridMode: GridMode
    @Binding var grainLevel: GrainLevel
    @Binding var lightLeakOn: Bool
    @Binding var vignetteOn: Bool
    @Binding var bloomOn: Bool
    let flashMode: FlashStyle
    let onFlashSet: (FlashStyle) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let tab = selectedTab {
                tabPanel(for: tab)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 0) {
                ForEach(CameraToolbarTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = selectedTab == tab ? nil : tab
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.label)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Color.lumePrimary : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
        }
    }

    @ViewBuilder
    private func tabPanel(for tab: CameraToolbarTab) -> some View {
        switch tab {
        case .grid: gridOptions
        case .texture: textureOptions
        case .fx: fxOptions
        case .flash: flashOptions
        }
    }

    private var gridOptions: some View {
        HStack(spacing: 12) {
            chipButton("No", selected: gridMode == .off) { gridMode = .off }
            chipButton("Tercios", selected: gridMode == .thirds) { gridMode = .thirds }
            chipButton("Centro", selected: gridMode == .center) { gridMode = .center }
            chipButton("Áureo", selected: gridMode == .golden) { gridMode = .golden }
        }
        .padding(.horizontal, 16)
    }

    private var textureOptions: some View {
        HStack(spacing: 12) {
            chipButton("No", selected: grainLevel == .off) { grainLevel = .off }
            chipButton("Leve", selected: grainLevel == .light) { grainLevel = .light }
            chipButton("Medio", selected: grainLevel == .medium) { grainLevel = .medium }
            chipButton("Fuerte", selected: grainLevel == .heavy) { grainLevel = .heavy }
        }
        .padding(.horizontal, 16)
    }

    private var fxOptions: some View {
        HStack(spacing: 12) {
            chipButton("Fuga de luz", selected: lightLeakOn) { lightLeakOn.toggle() }
            chipButton("Viñeta", selected: vignetteOn) { vignetteOn.toggle() }
            chipButton("Bloom", selected: bloomOn) { bloomOn.toggle() }
        }
        .padding(.horizontal, 16)
    }

    private var flashOptions: some View {
        HStack(spacing: 12) {
            chipButton("No", selected: flashMode == .off) { onFlashSet(.off) }
            chipButton("Sí", selected: flashMode == .on) { onFlashSet(.on) }
            chipButton("Auto", selected: flashMode == .auto) { onFlashSet(.auto) }
            chipButton("Vintage", selected: flashMode == .vintage) { onFlashSet(.vintage) }
        }
        .padding(.horizontal, 16)
    }

    private func chipButton(_ name: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.lumePrimary : Color.white.opacity(0.15))
                .foregroundColor(selected ? .black : .white)
                .cornerRadius(14)
        }
    }
}
