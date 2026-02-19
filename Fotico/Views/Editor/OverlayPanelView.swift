import SwiftUI

struct OverlayPanelView: View {
    @ObservedObject var editorVM: PhotoEditorViewModel
    @State private var selectedCategory: OverlayCategory? = nil  // nil = all

    private var filteredOverlays: [OverlayAsset] {
        if let category = selectedCategory {
            return OverlayAsset.allOverlays.filter { $0.category == category }
        }
        return OverlayAsset.allOverlays
    }

    var body: some View {
        VStack(spacing: 12) {
            // Intensity slider (shown when overlay is selected)
            if editorVM.editState.overlayId != nil {
                VStack(spacing: 4) {
                    HStack {
                        Text("Intensidad")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(editorVM.editState.overlayIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(Color.lumePrimary)
                    }
                    .padding(.horizontal)

                    Slider(value: Binding(
                        get: { editorVM.editState.overlayIntensity },
                        set: { editorVM.updateOverlayIntensity($0) }
                    ), in: 0...1, step: 0.01)
                        .tint(Color.lumePrimary)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
            }

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(name: "Todos", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(OverlayCategory.allCases, id: \.rawValue) { category in
                        categoryChip(name: category.displayName, icon: category.icon, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Overlay grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // None option
                    overlayButton(id: nil, name: "Ninguno", icon: "xmark.circle") {
                        editorVM.selectOverlay(nil)
                    }

                    ForEach(filteredOverlays) { overlay in
                        let isSelected = editorVM.editState.overlayId == overlay.id
                        Button {
                            HapticManager.selection()
                            editorVM.selectOverlay(overlay.id)
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.lumeSurface)
                                        .frame(width: 68, height: 68)

                                    Image(overlay.fileName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 68, height: 68)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? Color.lumePrimary : Color.clear, lineWidth: 2)
                                )

                                Text(overlay.displayName)
                                    .font(.caption2)
                                    .foregroundColor(isSelected ? Color.lumePrimary : .gray)
                                    .lineLimit(1)
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
            .background(isSelected ? Color.lumePrimary : Color.lumeSurface)
            .foregroundColor(isSelected ? .black : .gray)
            .cornerRadius(16)
        }
    }

    private func overlayButton(id: String?, name: String, icon: String, action: @escaping () -> Void) -> some View {
        let isSelected = id == nil && editorVM.editState.overlayId == nil
        return Button {
            HapticManager.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lumeSurface)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.lumePrimary : Color.clear, lineWidth: 2)
                    )

                Text(name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color.lumePrimary : .gray)
                    .lineLimit(1)
            }
        }
    }
}
