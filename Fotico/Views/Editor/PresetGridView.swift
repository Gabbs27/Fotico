import SwiftUI

struct PresetGridView: View {
    let presets: [FilterPreset]
    let selectedPresetId: String?
    @Binding var presetIntensity: Double
    let thumbnails: [String: UIImage]?
    let isPro: Bool
    let showIntensitySlider: Bool
    let onSelectPreset: (FilterPreset) -> Void
    let onDeselectPreset: () -> Void
    let onIntensityChange: ((Double) -> Void)?
    let onLockedPresetTapped: () -> Void

    @State private var selectedCategory: PresetCategory? = nil

    private var filteredPresets: [FilterPreset] {
        if let category = selectedCategory {
            return presets.filter { $0.category == category }
        }
        return presets
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Intensity slider
            if showIntensitySlider, selectedPresetId != nil {
                intensitySlider
            }

            // Category chips
            categoryChips
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    // Original (no filter)
                    gridItem(
                        id: nil,
                        name: "Original",
                        thumbnail: nil,
                        isLocked: false
                    ) {
                        HapticManager.selection()
                        onDeselectPreset()
                    }

                    ForEach(filteredPresets) { preset in
                        let isLocked = preset.tier == .pro && !isPro
                        gridItem(
                            id: preset.id,
                            name: preset.displayName,
                            thumbnail: thumbnails?[preset.id],
                            isLocked: isLocked
                        ) {
                            HapticManager.selection()
                            if isLocked {
                                onLockedPresetTapped()
                            } else {
                                onSelectPreset(preset)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Intensity Slider

    private var intensitySlider: some View {
        HStack(spacing: 10) {
            Text("Intensidad")
                .font(.caption2)
                .foregroundColor(.gray)

            Slider(value: $presetIntensity, in: 0...1, step: 0.01)
                .tint(Color.foticoPrimary)
                .onChange(of: presetIntensity) { _, newValue in
                    onIntensityChange?(newValue)
                }

            Text("\(Int(presetIntensity * 100))%")
                .font(.caption2)
                .foregroundColor(.white)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chipButton(name: "Todos", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(PresetCategory.allCases, id: \.rawValue) { category in
                    chipButton(name: category.displayName, icon: category.icon, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func chipButton(name: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.foticoPrimary : Color.foticoSurface)
            .foregroundColor(isSelected ? .black : .gray)
            .cornerRadius(14)
        }
    }

    // MARK: - Grid Item

    private func gridItem(id: String?, name: String, thumbnail: UIImage?, isLocked: Bool, action: @escaping () -> Void) -> some View {
        let isSelected = (id == nil && selectedPresetId == nil) || id == selectedPresetId

        return Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.foticoSurface)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: id == nil ? "photo" : "camera.filters")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            )
                    }

                    if isLocked {
                        PremiumBadge()
                            .offset(x: -4, y: 4)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.foticoPrimary : Color.clear, lineWidth: 2.5)
                )
                .scaleEffect(isSelected ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isSelected)

                Text(name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .gray)
                    .lineLimit(1)
            }
        }
    }
}
