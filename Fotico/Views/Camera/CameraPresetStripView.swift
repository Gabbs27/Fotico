import SwiftUI

/// Extracted preset strip to avoid re-renders from camera preview frame updates.
/// Only re-renders when selectedPreset changes.
struct CameraPresetStripView: View {
    let selectedPreset: FilterPreset?
    let onSelectPreset: (FilterPreset) -> Void
    let onDeselectPreset: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Original (deselect)
                chipButton(name: "Original", chipId: "original", isSelected: selectedPreset == nil) {
                    onDeselectPreset()
                }

                ForEach(FilterPreset.allPresets) { preset in
                    chipButton(name: preset.displayName, chipId: preset.id, isSelected: selectedPreset?.id == preset.id) {
                        onSelectPreset(preset)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.3))
    }

    private func chipButton(name: String, chipId: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            Text(name)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                    ? Color.white.opacity(0.25)
                    : Color.white.opacity(0.1)
                )
                .cornerRadius(16)
        }
        .id(chipId)
    }
}
