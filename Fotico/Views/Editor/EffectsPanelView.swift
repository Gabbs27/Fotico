import SwiftUI

struct EffectsPanelView: View {
    @ObservedObject var editorVM: PhotoEditorViewModel

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
                    CategoryChipView(name: "Todos", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
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
                    .foregroundColor(isActive ? Color.lumePrimary : .lumeDisabled)
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
                    .foregroundColor(isActive ? Color.lumePrimary : .lumeDisabled)
                    .lineLimit(1)
            }
            .accessibilityLabel(effect.displayName)
        }
    }

}
