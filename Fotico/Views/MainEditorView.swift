import SwiftUI
import SwiftData
import PhotosUI

struct MainEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var editorVM = PhotoEditorViewModel()
    @Binding var injectedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showDiscardAlert = false
    @State private var showPaywall = false
    @State private var showBeforeAfter = false

    private var subscriptionService: SubscriptionService { .shared }
    private var clipboard: EditClipboard { .shared }

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
                        editorVM.errorMessage = "Could not load the image"
                        pickerItem = nil
                        return
                    }
                    guard let image = UIImage(data: data) else {
                        editorVM.errorMessage = "The image is not valid"
                        pickerItem = nil
                        return
                    }
                    editorVM.loadImage(image)
                } catch {
                    editorVM.errorMessage = "Error loading: \(error.localizedDescription)"
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
        .alert("Saved", isPresented: $editorVM.exportSuccess) {
            Button("OK") {}
        } message: {
            Text("The image was saved to your gallery")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { capturedImage in
                editorVM.loadImage(capturedImage)
            }
        }
        .fullScreenCover(isPresented: $showBeforeAfter) {
            if let original = editorVM.originalImage?.toCIImage() {
                BeforeAfterView(
                    originalCIImage: original,
                    editedCIImage: editorVM.editedCIImage,
                    onDismiss: { showBeforeAfter = false }
                )
            }
        }
        .onChange(of: editorVM.showSaveProjectSheet) { _, show in
            if show {
                let name = "Photo \(Date().formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
                editorVM.saveAsProject(name: name, modelContext: modelContext)
                editorVM.showSaveProjectSheet = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Discard changes?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                editorVM.clearImage()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved edits. They will be lost if you leave.")
        }
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top toolbar
                topToolbar

                // Image preview
                ImagePreviewView(ciImage: editorVM.editedCIImage, uiImage: editorVM.editedImage, isProcessing: editorVM.isProcessing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if editorVM.editState.motionBlurMaskEnabled && editorVM.currentTool == .effects {
                            GeometryReader { geo in
                                MaskPaintingView(
                                    viewModel: editorVM,
                                    imageSize: editorVM.proxyImageSize,
                                    displaySize: geo.size
                                )
                            }
                        }
                    }
                    .overlay {
                        if editorVM.currentTool == .text && !editorVM.editState.textLayers.isEmpty {
                            GeometryReader { geo in
                                TextOverlayView(
                                    viewModel: editorVM,
                                    displaySize: geo.size
                                )
                            }
                        }
                    }

                // Tool panels with transition
                toolPanel
                    .frame(height: panelHeight(for: geometry.size.height))
                    .background(Color.lumeCardBg)
                    .animation(.easeInOut(duration: 0.25), value: editorVM.currentTool)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                // Bottom toolbar
                ToolBarView(selectedTool: $editorVM.currentTool)
            }
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
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")

            Spacer()

            HStack(spacing: LumeTokens.spacingLG) {
                Button {
                    editorVM.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(editorVM.canUndo ? .white : .lumeDisabled)
                        .frame(width: 44, height: 44)
                        .symbolEffect(.bounce, value: editorVM.canUndo)
                }
                .disabled(!editorVM.canUndo)
                .accessibilityLabel("Undo")

                Button {
                    editorVM.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundColor(editorVM.canRedo ? .white : .lumeDisabled)
                        .frame(width: 44, height: 44)
                        .symbolEffect(.bounce, value: editorVM.canRedo)
                }
                .disabled(!editorVM.canRedo)
                .accessibilityLabel("Redo")

                Button {
                    showBeforeAfter = true
                } label: {
                    Image(systemName: "eye")
                        .foregroundColor(!editorVM.editState.isDefault ? .white : .lumeDisabled)
                        .frame(width: 44, height: 44)
                }
                .disabled(editorVM.editState.isDefault)
                .accessibilityLabel("Before/After")
            }

            Spacer()

            HStack(spacing: LumeTokens.spacingLG) {
                Menu {
                    Button {
                        editorVM.copyEdits()
                    } label: {
                        Label("Copy adjustments", systemImage: "doc.on.doc")
                    }
                    .disabled(editorVM.editState.isDefault)

                    Button {
                        editorVM.pasteEdits()
                    } label: {
                        Label("Paste adjustments", systemImage: "doc.on.clipboard")
                    }
                    .disabled(!clipboard.hasContent)

                    Button(role: .destructive) {
                        editorVM.resetEdits()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(editorVM.editState.isDefault)

                    Divider()

                    Button {
                        editorVM.showSaveProjectSheet = true
                    } label: {
                        Label("Save project", systemImage: "folder.badge.plus")
                    }

                    Button {
                        EditShareService.presentShareSheet(editState: editorVM.editState)
                    } label: {
                        Label("Share edit", systemImage: "square.and.arrow.up")
                    }
                    .disabled(editorVM.editState.isDefault)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .accessibilityLabel("More options")

                Button {
                    Task { await editorVM.exportImage() }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(Color.lumePrimary)
                }
                .accessibilityLabel("Save image")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, LumeTokens.spacingSM)
        .background(Color.lumeCardBg)
    }

    // MARK: - Panel Height

    private func panelHeight(for screenHeight: CGFloat) -> CGFloat {
        switch editorVM.currentTool {
        case .crop: return screenHeight * 0.20
        case .presets: return screenHeight * 0.30
        case .adjust: return screenHeight * 0.28
        case .effects: return screenHeight * 0.30
        case .overlays: return screenHeight * 0.28
        case .colorTone: return screenHeight * 0.30
        case .hsl: return screenHeight * 0.30
        case .text: return screenHeight * 0.28
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
        case .colorTone:
            ColorTonePanelView(editState: $editorVM.editState) {
                editorVM.updateAdjustment()
            } onCommit: {
                editorVM.commitAdjustment()
            }
        case .crop:
            CropView(
                rotation: $editorVM.editState.rotation,
                cropAspectRatio: $editorVM.editState.cropAspectRatio,
                onRotationChanged: { editorVM.updateRotation(editorVM.editState.rotation) },
                onCommit: { editorVM.commitRotation() }
            )
        case .hsl:
            HSLPanelView(editState: $editorVM.editState) {
                editorVM.updateAdjustment()
            } onCommit: {
                editorVM.commitAdjustment()
            }
        case .text:
            TextToolPanelView(editorVM: editorVM)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LumeTokens.spacingXL) {
            Spacer()

            Text("LUMÉ")
                .font(.system(size: 48, weight: .bold, design: .default))
                .tracking(8)
                .foregroundColor(.white)

            Text("Film & Effects")
                .font(.subheadline)
                .foregroundColor(.lumeTextSecondary)

            Spacer().frame(height: 20)

            // Camera button
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, LumeTokens.spacingXXL)
                .padding(.vertical, LumeTokens.spacingLG)
                .background(Color.lumePrimary)
                .clipShape(RoundedRectangle(cornerRadius: LumeTokens.radiusLarge))
            }

            // Gallery button
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("Gallery")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, LumeTokens.spacingXXL)
                .padding(.vertical, LumeTokens.spacingLG)
                .background(Color.lumeSurface)
                .clipShape(RoundedRectangle(cornerRadius: LumeTokens.radiusLarge))
            }

            Spacer()
        }
    }
}

#Preview {
    MainEditorView(injectedImage: .constant(nil))
}
