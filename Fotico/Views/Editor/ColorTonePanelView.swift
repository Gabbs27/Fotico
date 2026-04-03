import SwiftUI

struct ColorTonePanelView: View {
    @Binding var editState: EditState
    let onUpdate: () -> Void
    let onCommit: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LumeTokens.spacingXL) {
                // Shadows section
                VStack(spacing: LumeTokens.spacingSM) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                            .foregroundColor(.lumePrimary)
                        Text("Shadows")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if editState.shadowToneSaturation > 0 {
                            Circle()
                                .fill(Color(hue: editState.shadowToneHue, saturation: editState.shadowToneSaturation, brightness: 0.8))
                                .frame(width: 16, height: 16)
                        }
                    }

                    toneSlider(label: "Color", value: Binding(
                        get: { editState.shadowToneHue },
                        set: { editState.shadowToneHue = $0; onUpdate() }
                    ), isHue: true)

                    toneSlider(label: "Intensity", value: Binding(
                        get: { editState.shadowToneSaturation },
                        set: { editState.shadowToneSaturation = $0; onUpdate() }
                    ), isHue: false)
                }

                Divider().background(Color.lumeTextSecondary.opacity(0.3))

                // Highlights section
                VStack(spacing: LumeTokens.spacingSM) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .font(.caption)
                            .foregroundColor(.lumePrimary)
                        Text("Highlights")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if editState.highlightToneSaturation > 0 {
                            Circle()
                                .fill(Color(hue: editState.highlightToneHue, saturation: editState.highlightToneSaturation, brightness: 0.9))
                                .frame(width: 16, height: 16)
                        }
                    }

                    toneSlider(label: "Color", value: Binding(
                        get: { editState.highlightToneHue },
                        set: { editState.highlightToneHue = $0; onUpdate() }
                    ), isHue: true)

                    toneSlider(label: "Intensity", value: Binding(
                        get: { editState.highlightToneSaturation },
                        set: { editState.highlightToneSaturation = $0; onUpdate() }
                    ), isHue: false)
                }

                // Reset button
                if editState.shadowToneSaturation > 0 || editState.highlightToneSaturation > 0 {
                    Button {
                        onCommit()
                        editState.shadowToneHue = 0
                        editState.shadowToneSaturation = 0
                        editState.highlightToneHue = 0
                        editState.highlightToneSaturation = 0
                        onUpdate()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.lumeWarning)
                    }
                }
            }
            .padding()
        }
    }

    private func toneSlider(label: String, value: Binding<Double>, isHue: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 65, alignment: .leading)

            if isHue {
                Slider(value: value, in: 0...1, step: 0.01) { editing in
                    if editing { onCommit() }
                }
                .tint(Color(hue: value.wrappedValue, saturation: 0.8, brightness: 0.9))
            } else {
                Slider(value: value, in: 0...1, step: 0.01) { editing in
                    if editing { onCommit() }
                }
                .tint(.lumePrimary)
            }

            Text("\(Int(value.wrappedValue * 100))")
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 30)
        }
    }
}
