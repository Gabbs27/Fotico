import SwiftUI
import Combine

struct PresetStripView: View {
    let presets: [FilterPreset]
    let selectedPresetId: String?
    @Binding var presetIntensity: Double
    let thumbnails: [String: UIImage]
    let onSelectPreset: (FilterPreset) -> Void
    let onDeselectPreset: () -> Void
    let onIntensityChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Intensity slider (shown when preset is selected)
            if selectedPresetId != nil {
                VStack(spacing: 4) {
                    HStack {
                        Text("Intensidad")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(presetIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    Slider(value: $presetIntensity, in: 0...1, step: 0.01)
                        .tint(.white)
                        .padding(.horizontal)
                        .onChange(of: presetIntensity) { _, newValue in
                            onIntensityChange(newValue)
                        }
                }
                .padding(.top, 8)
            }

            // Preset thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Original (no filter)
                    presetThumbnailButton(
                        id: nil,
                        name: "Original",
                        thumbnail: nil
                    ) {
                        onDeselectPreset()
                    }

                    ForEach(presets) { preset in
                        presetThumbnailButton(
                            id: preset.id,
                            name: preset.displayName,
                            thumbnail: thumbnails[preset.id]
                        ) {
                            onSelectPreset(preset)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func presetThumbnailButton(id: String?, name: String, thumbnail: UIImage?, action: @escaping () -> Void) -> some View {
        let isSelected = (id == nil && selectedPresetId == nil) || id == selectedPresetId
        return Button {
            HapticManager.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 68, height: 68)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? .white : Color.clear, lineWidth: 2)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.eastSurface)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: id == nil ? "photo" : "camera.filters")
                                .foregroundColor(.gray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? .white : Color.clear, lineWidth: 2)
                        )
                }

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .gray)
                    .lineLimit(1)
            }
        }
    }
}
