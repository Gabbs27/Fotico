import SwiftUI

struct TextOverlayView: View {
    @ObservedObject var viewModel: PhotoEditorViewModel
    let displaySize: CGSize

    var body: some View {
        ZStack {
            ForEach(viewModel.editState.textLayers) { layer in
                textElement(layer)
            }
        }
        .frame(width: displaySize.width, height: displaySize.height)
    }

    private func textElement(_ layer: TextLayer) -> some View {
        let x = layer.positionX * displaySize.width
        let y = layer.positionY * displaySize.height

        return Text(layer.text)
            .font(fontForStyle(layer.style, scale: layer.scale))
            .foregroundColor(colorForTextColor(layer.color))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            .position(x: x, y: y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        var updated = layer
                        updated.positionX = value.location.x / displaySize.width
                        updated.positionY = value.location.y / displaySize.height
                        viewModel.updateTextLayer(updated)
                    }
            )
    }

    private func fontForStyle(_ style: TextStyle, scale: Double) -> Font {
        let baseSize: CGFloat = 24 * scale
        switch style {
        case .minimal:
            return .system(size: baseSize, weight: .light)
        case .editorial:
            return .system(size: baseSize, weight: .bold, design: .serif)
        case .mono:
            return .system(size: baseSize, weight: .medium, design: .monospaced)
        case .analog:
            return .system(size: baseSize, weight: .regular, design: .serif).italic()
        }
    }

    private func colorForTextColor(_ color: TextColor) -> Color {
        let (r, g, b) = color.uiColor
        return Color(red: r, green: g, blue: b)
    }
}
