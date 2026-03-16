import SwiftUI

struct HSLPanelView: View {
    @Binding var editState: EditState
    let onUpdate: () -> Void
    let onCommit: () -> Void

    @State private var selectedColor: HSLColorRange = .red

    private func adjustmentBinding(for color: HSLColorRange) -> HSLAdjustment {
        editState.hslAdjustments[color.rawValue] ?? HSLAdjustment()
    }

    var body: some View {
        VStack(spacing: 12) {
            // Color selector chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(HSLColorRange.allCases, id: \.rawValue) { color in
                        Button {
                            HapticManager.selection()
                            selectedColor = color
                        } label: {
                            let (h, s, b) = color.displayColor
                            Circle()
                                .fill(Color(hue: h, saturation: s, brightness: b))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .overlay(
                                    // Show dot if this color has adjustments
                                    Group {
                                        if let adj = editState.hslAdjustments[color.rawValue], !adj.isDefault {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 6, height: 6)
                                                .offset(y: -18)
                                        }
                                    }
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            Text(selectedColor.displayName)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)

            // H/S/L sliders
            VStack(spacing: 10) {
                hslSlider(label: "Tono", value: Binding(
                    get: { adjustmentBinding(for: selectedColor).hue },
                    set: { newVal in
                        onCommit()
                        var adj = editState.hslAdjustments[selectedColor.rawValue] ?? HSLAdjustment()
                        adj.hue = newVal
                        editState.hslAdjustments[selectedColor.rawValue] = adj.isDefault ? nil : adj
                        onUpdate()
                    }
                ), range: -0.5...0.5)

                hslSlider(label: "Saturacion", value: Binding(
                    get: { adjustmentBinding(for: selectedColor).saturation },
                    set: { newVal in
                        onCommit()
                        var adj = editState.hslAdjustments[selectedColor.rawValue] ?? HSLAdjustment()
                        adj.saturation = newVal
                        editState.hslAdjustments[selectedColor.rawValue] = adj.isDefault ? nil : adj
                        onUpdate()
                    }
                ), range: -1.0...1.0)

                hslSlider(label: "Luminancia", value: Binding(
                    get: { adjustmentBinding(for: selectedColor).luminance },
                    set: { newVal in
                        onCommit()
                        var adj = editState.hslAdjustments[selectedColor.rawValue] ?? HSLAdjustment()
                        adj.luminance = newVal
                        editState.hslAdjustments[selectedColor.rawValue] = adj.isDefault ? nil : adj
                        onUpdate()
                    }
                ), range: -1.0...1.0)
            }
            .padding(.horizontal)

            // Reset button
            if !editState.hslAdjustments.isEmpty {
                Button {
                    onCommit()
                    editState.hslAdjustments.removeAll()
                    onUpdate()
                } label: {
                    Label("Restablecer", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.lumeWarning)
                }
            }
        }
    }

    private func hslSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 80, alignment: .leading)

            Slider(value: value, in: range, step: 0.01)
                .tint(.lumePrimary)

            Text("\(Int(value.wrappedValue * 100))")
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 35)
        }
    }
}
