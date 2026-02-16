import SwiftUI
import Combine

struct AdjustmentPanelView: View {
    @Binding var editState: EditState
    let onUpdate: () -> Void
    let onCommit: () -> Void

    // Track whether any slider is being dragged — commit undo on release
    @State private var isDragging = false

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
                    label: "Saturacion",
                    icon: "drop.fill",
                    value: $editState.saturation,
                    range: 0.0...2.0,
                    defaultValue: 1.0
                )
                adjustmentSlider(
                    label: "Exposicion",
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
                    .foregroundColor(Color.foticoPrimary)
                    .frame(width: 20)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text(formattedValue(value.wrappedValue, label: label))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(value.wrappedValue != defaultValue ? Color.foticoPrimary : .gray)

                if value.wrappedValue != defaultValue {
                    Button {
                        value.wrappedValue = defaultValue
                        onUpdate()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                            .foregroundColor(Color.foticoWarning)
                    }
                }
            }

            Slider(value: value, in: range)
                .tint(Color.foticoPrimary)
                .onChange(of: value.wrappedValue) { _, _ in
                    if !isDragging {
                        // First change from a new drag — push undo before modifications
                        isDragging = true
                        onCommit()
                    }
                    onUpdate()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { _ in
                            isDragging = false
                        }
                )
        }
    }

    private func formattedValue(_ value: Double, label: String) -> String {
        switch label {
        case "Temperatura":
            return "\(Int(value))K"
        case "Tinte":
            return value >= 0 ? "+\(Int(value))" : "\(Int(value))"
        default:
            if value >= 0 {
                return "+\(String(format: "%.2f", value))"
            }
            return String(format: "%.2f", value)
        }
    }
}
