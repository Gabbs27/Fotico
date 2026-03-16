import SwiftUI

struct TextToolPanelView: View {
    @ObservedObject var editorVM: PhotoEditorViewModel
    @State private var selectedLayerId: String?

    private var selectedLayer: TextLayer? {
        guard let id = selectedLayerId else { return nil }
        return editorVM.editState.textLayers.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 12) {
            if let layer = selectedLayer {
                // Edit selected layer
                VStack(spacing: 10) {
                    // Text input
                    HStack {
                        TextField("Texto", text: Binding(
                            get: { layer.text },
                            set: { newText in
                                var updated = layer
                                updated.text = newText
                                editorVM.updateTextLayer(updated)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                        Button {
                            editorVM.removeTextLayer(layer.id)
                            selectedLayerId = nil
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.lumeWarning)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)

                    // Style picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TextStyle.allCases, id: \.rawValue) { style in
                                Button {
                                    var updated = layer
                                    updated.style = style
                                    editorVM.updateTextLayer(updated)
                                } label: {
                                    Text(style.displayName)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(layer.style == style ? Color.lumePrimary : Color.lumeSurface)
                                        .foregroundColor(layer.style == style ? .black : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Color picker
                    HStack(spacing: 12) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)

                        ForEach(TextColor.allCases, id: \.rawValue) { color in
                            Button {
                                var updated = layer
                                updated.color = color
                                editorVM.updateTextLayer(updated)
                            } label: {
                                let (r, g, b) = color.uiColor
                                Circle()
                                    .fill(Color(red: r, green: g, blue: b))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(layer.color == color ? Color.lumePrimary : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Scale slider
                    HStack {
                        Text("Tamaño")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)
                        Slider(value: Binding(
                            get: { layer.scale },
                            set: { newScale in
                                var updated = layer
                                updated.scale = newScale
                                editorVM.updateTextLayer(updated)
                            }
                        ), in: 0.3...3.0, step: 0.1)
                        .tint(.lumePrimary)
                    }
                    .padding(.horizontal)
                }
            } else {
                // No layer selected — show list or add button
                if editorVM.editState.textLayers.isEmpty {
                    VStack(spacing: 12) {
                        Text("Sin texto")
                            .font(.caption)
                            .foregroundColor(.lumeTextSecondary)

                        Button {
                            editorVM.addTextLayer()
                            selectedLayerId = editorVM.editState.textLayers.last?.id
                        } label: {
                            Label("Agregar texto", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.lumePrimary)
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(editorVM.editState.textLayers) { layer in
                                Button {
                                    selectedLayerId = layer.id
                                } label: {
                                    HStack {
                                        Text(layer.text)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(layer.style.displayName)
                                            .font(.caption2)
                                            .foregroundColor(.lumeTextSecondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.lumeSurface)
                                    .cornerRadius(8)
                                }
                            }

                            Button {
                                editorVM.addTextLayer()
                                selectedLayerId = editorVM.editState.textLayers.last?.id
                            } label: {
                                Label("Agregar", systemImage: "plus")
                                    .font(.caption)
                                    .foregroundColor(.lumePrimary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}
