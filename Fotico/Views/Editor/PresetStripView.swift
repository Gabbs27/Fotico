import SwiftUI

struct PresetStripView: View {
    let presets: [FilterPreset]
    let selectedPresetId: String?
    @Binding var presetIntensity: Double
    let thumbnails: [String: UIImage]
    let isPro: Bool
    let onSelectPreset: (FilterPreset) -> Void
    let onDeselectPreset: () -> Void
    let onIntensityChange: (Double) -> Void
    let onLockedPresetTapped: () -> Void

    @State private var selectedCategory: PresetCategory? = nil  // nil = "Todos"

    private var filteredPresets: [FilterPreset] {
        if let category = selectedCategory {
            return presets.filter { $0.category == category }
        }
        return presets
    }

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

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "Todos" chip
                    categoryChip(name: "Todos", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(PresetCategory.allCases, id: \.rawValue) { category in
                        categoryChip(name: category.displayName, icon: category.icon, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Preset thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Original (no filter)
                    presetThumbnailButton(
                        id: nil,
                        name: "Original",
                        thumbnail: nil,
                        isLocked: false
                    ) {
                        onDeselectPreset()
                    }

                    ForEach(filteredPresets) { preset in
                        let isLocked = preset.tier == .pro && !isPro
                        presetThumbnailButton(
                            id: preset.id,
                            name: preset.displayName,
                            thumbnail: thumbnails[preset.id],
                            isLocked: isLocked
                        ) {
                            if isLocked {
                                onLockedPresetTapped()
                            } else {
                                onSelectPreset(preset)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func categoryChip(name: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.foticoPrimary : Color.foticoSurface)
            .foregroundColor(isSelected ? .black : .gray)
            .cornerRadius(16)
        }
    }

    private func presetThumbnailButton(id: String?, name: String, thumbnail: UIImage?, isLocked: Bool, action: @escaping () -> Void) -> some View {
        let isSelected = (id == nil && selectedPresetId == nil) || id == selectedPresetId
        return Button {
            HapticManager.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 68, height: 68)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.foticoPrimary : Color.clear, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.foticoSurface)
                            .frame(width: 68, height: 68)
                            .overlay(
                                Image(systemName: id == nil ? "photo" : "camera.filters")
                                    .foregroundColor(.gray)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.foticoPrimary : Color.clear, lineWidth: 2)
                            )
                    }

                    if isLocked {
                        PremiumBadge()
                            .offset(x: 4, y: -4)
                    }
                }

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .gray)
                    .lineLimit(1)
            }
        }
    }
}
