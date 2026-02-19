import SwiftUI

struct EffectsPanelView: View {
    @ObservedObject var editorVM: PhotoEditorViewModel

    @State private var selectedEffect: EffectType?

    var body: some View {
        VStack(spacing: 12) {
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
                    ForEach(EffectType.allCases) { effect in
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
                    .foregroundColor(isActive ? Color.lumePrimary : .gray)
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
                    .foregroundColor(isActive ? Color.lumePrimary : .gray)
                    .lineLimit(1)
            }
        }
    }
}
