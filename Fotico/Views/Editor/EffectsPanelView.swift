import SwiftUI

struct EffectsPanelView: View {
    var editorVM: PhotoEditorViewModel

    @State private var selectedEffect: EffectType?
    @State private var selectedCategory: EffectCategory? = nil

    private var filteredEffects: [EffectType] {
        if let cat = selectedCategory {
            return EffectType.allCases.filter { $0.category == cat }
        }
        return Array(EffectType.allCases)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChipView(name: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(EffectCategory.allCases, id: \.rawValue) { cat in
                        CategoryChipView(name: cat.rawValue, icon: cat.icon, isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)

            // Effect intensity slider (shown when effect is selected)
            if let effect = selectedEffect {
                VStack(spacing: 4) {
                    HStack {
                        Text(effect.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(editorVM.effectIntensity(for: effect) * 100))%")
                            .font(.caption)
                            .foregroundColor(Color.lumePrimary)

                        if editorVM.effectIntensity(for: effect) > 0 {
                            Button {
                                editorVM.commitAdjustment()
                                editorVM.updateEffect(effect, intensity: 0)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.lumeWarning)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    Slider(
                        value: Binding(
                            get: { editorVM.effectIntensity(for: effect) },
                            set: { editorVM.updateEffect(effect, intensity: $0) }
                        ),
                        in: 0...1,
                        step: 0.01
                    )
                    .tint(Color.lumePrimary)
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }

            // Motion Blur extra controls
            if selectedEffect == .motionBlur {
                VStack(spacing: 12) {
                    // Direction slider
                    HStack {
                        Text("Direction")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)
                        Spacer()
                        Text("\(Int(editorVM.editState.motionBlurAngle))°")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)
                    }
                    Slider(value: Binding(
                        get: { editorVM.editState.motionBlurAngle },
                        set: { editorVM.updateMotionBlurAngle($0) }
                    ), in: 0...360, step: 1)
                    .tint(.lumePrimary)

                    // Mask controls row
                    HStack(spacing: 12) {
                        Button {
                            editorVM.toggleMotionBlurMask()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: editorVM.editState.motionBlurMaskEnabled ? "paintbrush.fill" : "paintbrush")
                                Text(editorVM.editState.motionBlurMaskEnabled ? "MASK: ON" : "MASK: OFF")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(editorVM.editState.motionBlurMaskEnabled ? Color.lumePrimary : Color.clear)
                            .foregroundStyle(editorVM.editState.motionBlurMaskEnabled ? Color.lumeDark : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: LumeTokens.radiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: LumeTokens.radiusSmall)
                                    .stroke(Color.lumeDivider, lineWidth: 1)
                            )
                        }

                        if editorVM.editState.motionBlurMaskEnabled {
                            Button {
                                editorVM.maskBrushMode = editorVM.maskBrushMode == .brush ? .eraser : .brush
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: editorVM.maskBrushMode == .brush ? "paintbrush.pointed.fill" : "eraser.fill")
                                    Text(editorVM.maskBrushMode == .brush ? "Brush" : "Eraser")
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.lumeSurface)
                                .clipShape(RoundedRectangle(cornerRadius: LumeTokens.radiusSmall))
                            }

                            // In/Out toggle — controls whether blur applies inside or outside painted area
                            Button {
                                editorVM.toggleMotionBlurMaskInvert()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: editorVM.editState.motionBlurMaskInverted ? "rectangle.dashed.badge.record" : "rectangle.inset.filled")
                                    Text(editorVM.editState.motionBlurMaskInverted ? "Out" : "In")
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(editorVM.editState.motionBlurMaskInverted ? Color.orange.opacity(0.2) : Color.lumeSurface)
                                .clipShape(RoundedRectangle(cornerRadius: LumeTokens.radiusSmall))
                            }
                        }

                        Spacer()
                    }

                    if editorVM.editState.motionBlurMaskEnabled {
                        HStack {
                            Text("Size")
                                .font(.caption)
                                .foregroundColor(.lumeTextSecondary)
                            Slider(value: $editorVM.maskBrushSize, in: 10...100, step: 1)
                                .tint(.lumePrimary)
                            Text("\(Int(editorVM.maskBrushSize))")
                                .font(.caption)
                                .foregroundColor(.lumeTextSecondary)
                                .frame(width: 30)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Effect grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredEffects) { effect in
                        effectButton(effect)
                    }
                }
                .padding()
            }
        }
    }

    private func effectButton(_ effect: EffectType) -> some View {
        let isActive = editorVM.effectIntensity(for: effect) > 0
        let isSelected = selectedEffect == effect

        return Button {
            HapticManager.selection()
            if selectedEffect == effect {
                selectedEffect = nil
            } else {
                selectedEffect = effect
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: effect.icon)
                    .font(.title2)
                    .foregroundColor(isActive ? Color.lumePrimary : .lumeTextSecondary)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.lumePrimary.opacity(0.15) : Color.lumeSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.lumePrimary : Color.clear, lineWidth: 1.5)
                    )

                Text(effect.displayName)
                    .font(.caption2)
                    .foregroundColor(isActive ? Color.lumePrimary : .lumeTextSecondary)
                    .lineLimit(1)
            }
            .accessibilityLabel(effect.displayName)
        }
    }

}
