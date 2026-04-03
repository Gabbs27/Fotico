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

    @State private var selectedCategory: PresetCategory? = .featured
    @AppStorage("favoritePresetIds") private var favoritePresetIdsString: String = ""
    @State private var showFavoritesOnly = false

    private var favoritePresetIds: Set<String> {
        Set(favoritePresetIdsString.split(separator: ",").map(String.init))
    }

    private func toggleFavorite(_ presetId: String) {
        var ids = favoritePresetIds
        if ids.contains(presetId) {
            ids.remove(presetId)
        } else {
            ids.insert(presetId)
        }
        favoritePresetIdsString = ids.sorted().joined(separator: ",")
    }

    private var filteredPresets: [FilterPreset] {
        if showFavoritesOnly {
            return presets.filter { favoritePresetIds.contains($0.id) }
        }
        if let category = selectedCategory {
            return presets.filter { $0.category == category }
        }
        return presets
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
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
                LazyVGrid(columns: columns, spacing: 8) {
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
                            name: preset.name,
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
            Text("Intensity")
                .font(.caption2)
                .foregroundColor(.lumeTextSecondary)

            Slider(value: $presetIntensity, in: 0...1, step: 0.01)
                .tint(Color.lumePrimary)
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
                CategoryChipView(name: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil && !showFavoritesOnly) {
                    selectedCategory = nil
                    showFavoritesOnly = false
                }

                CategoryChipView(
                    name: "\u{2605}",
                    icon: "star.fill",
                    isSelected: showFavoritesOnly
                ) {
                    showFavoritesOnly.toggle()
                    if showFavoritesOnly { selectedCategory = nil }
                }

                ForEach(PresetCategory.allCases, id: \.rawValue) { category in
                    CategoryChipView(name: category.displayName, icon: category.icon, isSelected: selectedCategory == category) {
                        selectedCategory = category
                        showFavoritesOnly = false
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Grid Item

    private func gridItem(id: String?, name: String, thumbnail: UIImage?, isLocked: Bool, action: @escaping () -> Void) -> some View {
        let isSelected = (id == nil && selectedPresetId == nil) || id == selectedPresetId

        return Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if let thumbnail {
                        // Square container first, then fill+clip inside
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.lumeSurface)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: id == nil ? "photo" : "camera.filters")
                                    .font(.body)
                                    .foregroundColor(.lumeTextSecondary)
                            )
                    }

                    if isLocked {
                        PremiumBadge()
                            .offset(x: -3, y: 3)
                    }

                    if id != nil {
                        Button {
                            HapticManager.impact(.light)
                            toggleFavorite(id!)
                        } label: {
                            Image(systemName: favoritePresetIds.contains(id!) ? "heart.fill" : "heart")
                                .font(.caption2)
                                .foregroundColor(favoritePresetIds.contains(id!) ? .red : .white.opacity(0.7))
                                .padding(6)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                                .contentShape(Circle().inset(by: -4))
                        }
                        .offset(x: 3, y: -3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.lumePrimary : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isSelected)

                Text(name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .lumeTextSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(name)
    }
}
