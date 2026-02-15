import SwiftUI
import PhotosUI
import Combine

struct MainEditorView: View {
    @StateObject private var editorVM = PhotoEditorViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color.eastDark.ignoresSafeArea()

            if editorVM.hasImage {
                editorContent
            } else {
                emptyState
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: pickerItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    editorVM.loadImage(image)
                }
                pickerItem = nil
            }
        }
        .alert("Error", isPresented: .init(
            get: { editorVM.errorMessage != nil },
            set: { if !$0 { editorVM.errorMessage = nil } }
        )) {
            Button("OK") { editorVM.errorMessage = nil }
        } message: {
            Text(editorVM.errorMessage ?? "")
        }
        .alert("Guardado", isPresented: $editorVM.exportSuccess) {
            Button("OK") {}
        } message: {
            Text("La imagen se guardo en tu galeria")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { capturedImage in
                editorVM.loadImage(capturedImage)
            }
        }
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar

            // Image preview
            ImagePreviewView(image: editorVM.editedImage, isProcessing: editorVM.isProcessing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tool panels
            toolPanel
                .frame(height: 280)
                .background(Color.eastCardBg)

            // Bottom toolbar
            ToolBarView(selectedTool: $editorVM.currentTool)
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            Button {
                editorVM.clearImage()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    editorVM.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(editorVM.canUndo ? .white : .gray)
                }
                .disabled(!editorVM.canUndo)

                Button {
                    editorVM.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundColor(editorVM.canRedo ? .white : .gray)
                }
                .disabled(!editorVM.canRedo)
            }

            Spacer()

            HStack(spacing: 16) {
                if !editorVM.editState.isDefault {
                    Button {
                        editorVM.resetEdits()
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                            .foregroundColor(Color.eastWarning)
                    }
                }

                Button {
                    Task { await editorVM.exportImage() }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(Color.eastPrimary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.eastCardBg)
    }

    // MARK: - Tool Panel

    @ViewBuilder
    private var toolPanel: some View {
        switch editorVM.currentTool {
        case .presets:
            PresetStripView(
                presets: FilterPreset.allPresets,
                selectedPresetId: editorVM.editState.selectedPresetId,
                presetIntensity: $editorVM.editState.presetIntensity,
                thumbnails: editorVM.presetThumbnails,
                onSelectPreset: { editorVM.selectPreset($0) },
                onDeselectPreset: { editorVM.deselectPreset() },
                onIntensityChange: { editorVM.updatePresetIntensity($0) }
            )
        case .adjust:
            AdjustmentPanelView(editState: $editorVM.editState) {
                editorVM.updateAdjustment()
            } onCommit: {
                editorVM.commitAdjustment()
            }
        case .effects:
            EffectsPanelView(editorVM: editorVM)
        case .crop:
            CropView(
                rotation: $editorVM.editState.rotation,
                onRotationChanged: { editorVM.updateRotation(editorVM.editState.rotation) },
                onCommit: { editorVM.commitRotation() }
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("EAST")
                .font(.system(size: 48, weight: .bold, design: .default))
                .tracking(8)
                .foregroundColor(.white)

            Text("Film & Effects")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer().frame(height: 20)

            // Camera button
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Camara")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
            }

            // Gallery button
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("Galeria")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.eastSurface)
                .cornerRadius(12)
            }

            Spacer()
        }
    }
}

#Preview {
    MainEditorView()
}
