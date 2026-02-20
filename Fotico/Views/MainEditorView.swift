import SwiftUI
import SwiftData
import PhotosUI

struct MainEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var editorVM = PhotoEditorViewModel()
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var clipboard = EditClipboard.shared
    @Binding var injectedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showDiscardAlert = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.lumeDark.ignoresSafeArea()

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
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        editorVM.errorMessage = "No se pudo cargar la imagen"
                        pickerItem = nil
                        return
                    }
                    guard let image = UIImage(data: data) else {
                        editorVM.errorMessage = "La imagen no es valida"
                        pickerItem = nil
                        return
                    }
                    editorVM.loadImage(image)
                } catch {
                    editorVM.errorMessage = "Error al cargar: \(error.localizedDescription)"
                }
                pickerItem = nil
            }
        }
        .onChange(of: injectedImage) { _, newImage in
            if let image = newImage {
                editorVM.loadImage(image)
                injectedImage = nil
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
            Text("La imagen se guardó en tu galería")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { capturedImage in
                editorVM.loadImage(capturedImage)
            }
        }
        .onChange(of: editorVM.showSaveProjectSheet) { _, show in
            if show {
                let name = "Foto \(Date().formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
                editorVM.saveAsProject(name: name, modelContext: modelContext)
                editorVM.showSaveProjectSheet = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Descartar cambios?", isPresented: $showDiscardAlert) {
            Button("Descartar", role: .destructive) {
                editorVM.clearImage()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tienes ediciones sin guardar. Si sales se perderan.")
        }
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar

            // Image preview — GPU-rendered via MetalImageView (no CGImage creation)
            ImagePreviewView(ciImage: editorVM.editedCIImage, uiImage: editorVM.editedImage, isProcessing: editorVM.isProcessing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tool panels
            toolPanel
                .frame(height: panelHeight)
                .background(Color.lumeCardBg)
                .animation(.easeInOut(duration: 0.2), value: editorVM.currentTool)

            // Bottom toolbar
            ToolBarView(selectedTool: $editorVM.currentTool)
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            Button {
                if editorVM.editState.isDefault {
                    editorVM.clearImage()
                } else {
                    showDiscardAlert = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Cerrar")

            Spacer()

            HStack(spacing: 16) {
                Button {
                    editorVM.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(editorVM.canUndo ? .white : .lumeDisabled)
                }
                .disabled(!editorVM.canUndo)
                .accessibilityLabel("Deshacer")

                Button {
                    editorVM.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundColor(editorVM.canRedo ? .white : .lumeDisabled)
                }
                .disabled(!editorVM.canRedo)
                .accessibilityLabel("Rehacer")
            }

            Spacer()

            HStack(spacing: 16) {
                Menu {
                    Button {
                        editorVM.copyEdits()
                    } label: {
                        Label("Copiar ajustes", systemImage: "doc.on.doc")
                    }
                    .disabled(editorVM.editState.isDefault)

                    Button {
                        editorVM.pasteEdits()
                    } label: {
                        Label("Pegar ajustes", systemImage: "doc.on.clipboard")
                    }
                    .disabled(!clipboard.hasContent)

                    Button(role: .destructive) {
                        editorVM.resetEdits()
                    } label: {
                        Label("Restablecer", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(editorVM.editState.isDefault)

                    Divider()

                    Button {
                        editorVM.showSaveProjectSheet = true
                    } label: {
                        Label("Guardar proyecto", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .accessibilityLabel("Más opciones")

                Button {
                    Task { await editorVM.exportImage() }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(Color.lumePrimary)
                }
                .accessibilityLabel("Guardar imagen")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.lumeCardBg)
    }

    // MARK: - Panel Height

    private var panelHeight: CGFloat {
        switch editorVM.currentTool {
        case .crop: return 180
        case .presets: return 300
        case .adjust: return 280
        case .effects: return 300
        case .overlays: return 280
        }
    }

    // MARK: - Tool Panel

    @ViewBuilder
    private var toolPanel: some View {
        switch editorVM.currentTool {
        case .presets:
            PresetGridView(
                presets: FilterPreset.allPresets,
                selectedPresetId: editorVM.editState.selectedPresetId,
                presetIntensity: $editorVM.editState.presetIntensity,
                thumbnails: editorVM.presetThumbnails,
                isPro: subscriptionService.isPro,
                showIntensitySlider: true,
                onSelectPreset: { editorVM.selectPreset($0) },
                onDeselectPreset: { editorVM.deselectPreset() },
                onIntensityChange: { editorVM.updatePresetIntensity($0) },
                onLockedPresetTapped: { showPaywall = true }
            )
        case .adjust:
            AdjustmentPanelView(editState: $editorVM.editState) {
                editorVM.updateAdjustment()
            } onCommit: {
                editorVM.commitAdjustment()
            }
        case .effects:
            EffectsPanelView(editorVM: editorVM)
        case .overlays:
            OverlayPanelView(editorVM: editorVM)
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

            Text("LUMÉ")
                .font(.system(size: 48, weight: .bold, design: .default))
                .tracking(8)
                .foregroundColor(.white)

            Text("Film y Efectos")
                .font(.subheadline)
                .foregroundColor(.lumeTextSecondary)

            Spacer().frame(height: 20)

            // Camera button
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Cámara")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.lumePrimary)
                .cornerRadius(12)
            }

            // Gallery button
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("Galería")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.lumeSurface)
                .cornerRadius(12)
            }

            Spacer()
        }
    }
}

#Preview {
    MainEditorView(injectedImage: .constant(nil))
}
