import SwiftUI

struct AdjustmentPanelView: View {
    @Binding var editState: EditState
    let onUpdate: () -> Void
    let onCommit: () -> Void

    // Track whether any slider is being dragged — commit undo when drag starts
    @State private var isEditing = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                adjustmentSlider(
                    label: "Brillo",
                    icon: "sun.max",
                    value: $editState.brightness,
                    range: -1.0...1.0,
                    defaultValue: 0
                )
                adjustmentSlider(
                    label: "Contraste",
                    icon: "circle.righthalf.filled",
                    value: $editState.contrast,
                    range: 0.25...4.0,
                    defaultValue: 1.0
                )
                adjustmentSlider(
                    label: "Saturación",
                    icon: "drop.fill",
                    value: $editState.saturation,
                    range: 0.0...2.0,
                    defaultValue: 1.0
                )
                adjustmentSlider(
                    label: "Exposición",
                    icon: "plusminus.circle",
                    value: $editState.exposure,
                    range: -2.0...2.0,
                    defaultValue: 0
                )
                adjustmentSlider(
                    label: "Temperatura",
                    icon: "thermometer.medium",
                    value: $editState.temperature,
                    range: 2000...10000,
                    defaultValue: 6500
                )
                adjustmentSlider(
                    label: "Tinte",
                    icon: "paintpalette",
                    value: $editState.tint,
                    range: -150...150,
                    defaultValue: 0
                )
                adjustmentSlider(
                    label: "Vibrancia",
                    icon: "wand.and.stars",
                    value: $editState.vibrance,
                    range: -1.0...1.0,
                    defaultValue: 0
                )
                adjustmentSlider(
                    label: "Nitidez",
                    icon: "triangle",
                    value: $editState.sharpness,
                    range: 0.0...2.0,
                    defaultValue: 0
                )
            }
            .padding()
        }
    }

    private func adjustmentSlider(
        label: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.lumePrimary)
                    .frame(width: 20)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.lumeTextSecondary)

                Spacer()

                Text(formattedValue(value.wrappedValue, label: label))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(value.wrappedValue != defaultValue ? Color.lumePrimary : .lumeTextSecondary)

                if value.wrappedValue != defaultValue {
                    Button {
                        onCommit()
                        value.wrappedValue = defaultValue
                        onUpdate()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                            .foregroundColor(Color.lumeWarning)
                    }
                }
            }

            Slider(value: value, in: range, onEditingChanged: { editing in
                if editing && !isEditing {
                    // Drag started — push undo state before modifications
                    isEditing = true
                    onCommit()
                } else if !editing {
                    isEditing = false
                }
            })
            .tint(Color.lumePrimary)
            .onChange(of: value.wrappedValue) { _, _ in
                onUpdate()
            }
        }
    }

    private func formattedValue(_ value: Double, label: String) -> String {
        switch label {
        case "Temperatura":
            // 6500K is neutral, map to relative scale
            let normalized = Int((value - 6500) / 35)
            return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
        case "Tinte":
            return value >= 0 ? "+\(Int(value))" : "\(Int(value))"
        case "Contraste", "Saturación":
            // 1.0 is neutral (display as 0), range 0-2 maps to -100 to +100
            let normalized = Int((value - 1.0) * 100)
            return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
        case "Brillo":
            // 0 is neutral, range -1 to 1 maps to -100 to +100
            let normalized = Int(value * 100)
            return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
        case "Exposición":
            // 0 is neutral, show with 1 decimal
            let formatted = String(format: "%+.1f", value)
            return formatted
        case "Vibrancia", "Nitidez":
            let normalized = Int(value * 100)
            return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
        default:
            let normalized = Int(value * 100)
            return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
        }
    }
}
