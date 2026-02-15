import SwiftUI
import CoreImage
import Combine

@MainActor
class PhotoEditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var editedImage: UIImage?
    @Published var editState = EditState()
    @Published var isProcessing = false
    @Published var presetThumbnails: [String: UIImage] = [:]
    @Published var currentTool: EditorTool = .presets
    @Published var showExportSheet = false
    @Published var showImagePicker = false
    @Published var errorMessage: String?
    @Published var exportSuccess = false

    private let filterService = ImageFilterService()
    private let metalService = MetalKernelService()
    private let libraryService = PhotoLibraryService()
    private var originalCIImage: CIImage?
    private var proxyCIImage: CIImage?       // Downscaled for live editing
    private var renderTask: Task<Void, Never>?
    private let renderQueue = DispatchQueue(label: "com.east.render", qos: .userInteractive)

    // Undo/Redo
    private var undoStack: [EditState] = []
    private var redoStack: [EditState] = []
    @Published var canUndo = false
    @Published var canRedo = false

    var hasImage: Bool { originalImage != nil }

    // MARK: - Image Loading

    func loadImage(_ image: UIImage) {
        originalImage = image
        originalCIImage = image.toCIImage()

        // Create proxy (downscaled) for fast live editing
        if let ciImage = originalCIImage {
            proxyCIImage = Self.createProxy(from: ciImage)
        }

        editState = EditState()
        undoStack = []
        redoStack = []
        canUndo = false
        canRedo = false
        editedImage = image
        generatePresetThumbnails()
    }

    nonisolated private static func createProxy(from ciImage: CIImage) -> CIImage {
        let extent = ciImage.extent
        let maxDim = max(extent.width, extent.height)
        if maxDim <= 1200 { return ciImage }
        let scale = 1200.0 / maxDim
        return ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    // MARK: - Preset Application

    func selectPreset(_ preset: FilterPreset) {
        pushUndo()
        if editState.selectedPresetId == preset.id {
            editState.selectedPresetId = nil
            editState.presetIntensity = 1.0
        } else {
            editState.selectedPresetId = preset.id
            editState.presetIntensity = preset.defaultIntensity
        }
        applyEditsDebounced()
    }

    func deselectPreset() {
        pushUndo()
        editState.selectedPresetId = nil
        editState.presetIntensity = 1.0
        applyEditsDebounced()
    }

    func updatePresetIntensity(_ intensity: Double) {
        editState.presetIntensity = intensity
        applyEditsDebounced()
    }

    // MARK: - Adjustments

    func updateAdjustment() {
        applyEditsDebounced()
    }

    func commitAdjustment() {
        pushUndo()
    }

    // MARK: - Crop & Rotation

    func updateRotation(_ degrees: Double) {
        editState.rotation = degrees
        applyEditsDebounced()
    }

    func commitRotation() {
        pushUndo()
    }

    // MARK: - Effects

    func updateEffect(_ effect: EffectType, intensity: Double) {
        switch effect {
        case .grain: editState.grainIntensity = intensity
        case .lightLeak: editState.lightLeakIntensity = intensity
        case .bloom: editState.bloomIntensity = intensity
        case .vignette: editState.vignetteIntensity = intensity
        case .solarize: editState.solarizeThreshold = intensity
        case .glitch: editState.glitchIntensity = intensity
        case .fisheye: editState.fisheyeIntensity = intensity
        case .threshold: editState.thresholdLevel = intensity
        }
        applyEditsDebounced()
    }

    func effectIntensity(for effect: EffectType) -> Double {
        switch effect {
        case .grain: return editState.grainIntensity
        case .lightLeak: return editState.lightLeakIntensity
        case .bloom: return editState.bloomIntensity
        case .vignette: return editState.vignetteIntensity
        case .solarize: return editState.solarizeThreshold
        case .glitch: return editState.glitchIntensity
        case .fisheye: return editState.fisheyeIntensity
        case .threshold: return editState.thresholdLevel
        }
    }

    // MARK: - Rendering (background thread with proxy)

    private func applyEditsDebounced() {
        renderTask?.cancel()
        renderTask = Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms debounce
            guard !Task.isCancelled else { return }
            await applyEditsInBackground()
        }
    }

    private func applyEditsInBackground() async {
        guard let proxyImage = proxyCIImage else { return }
        isProcessing = true

        let state = editState
        let service = filterService
        let queue = renderQueue

        let rendered: UIImage? = await withCheckedContinuation { continuation in
            queue.async {
                let result = service.applyEdits(
                    to: proxyImage,
                    state: state,
                    presets: FilterPreset.allPresets
                )
                let image = service.renderToUIImage(result)
                continuation.resume(returning: image)
            }
        }

        guard !Task.isCancelled else { return }
        if let rendered {
            editedImage = rendered
        }
        isProcessing = false
    }

    // MARK: - Thumbnails (background)

    private func generatePresetThumbnails() {
        guard let ciImage = originalCIImage else { return }
        let service = filterService
        let queue = renderQueue

        Task {
            let thumbnails: [String: UIImage] = await withCheckedContinuation { continuation in
                queue.async {
                    var results: [String: UIImage] = [:]
                    let thumbnailSize = CGSize(width: 80, height: 80)
                    for preset in FilterPreset.allPresets {
                        if let thumbnail = service.generateThumbnail(
                            from: ciImage,
                            preset: preset,
                            size: thumbnailSize
                        ) {
                            results[preset.id] = thumbnail
                        }
                    }
                    continuation.resume(returning: results)
                }
            }
            self.presetThumbnails = thumbnails
        }
    }

    // MARK: - Export (full resolution on background)

    func exportImage() async {
        guard let fullImage = originalCIImage else { return }
        isProcessing = true

        let state = editState
        let service = filterService
        let queue = renderQueue

        let rendered: UIImage? = await withCheckedContinuation { continuation in
            queue.async {
                let result = service.applyEdits(
                    to: fullImage,
                    state: state,
                    presets: FilterPreset.allPresets
                )
                let image = service.renderToUIImage(result)
                continuation.resume(returning: image)
            }
        }

        guard let exportImage = rendered else {
            errorMessage = "Error al procesar la imagen"
            isProcessing = false
            return
        }

        do {
            try await libraryService.saveToPhotoLibrary(exportImage)
            exportSuccess = true
            HapticManager.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }

        isProcessing = false
    }

    // MARK: - Undo/Redo

    private func pushUndo() {
        undoStack.append(editState)
        redoStack.removeAll()
        canUndo = true
        canRedo = false
    }

    func undo() {
        guard let previousState = undoStack.popLast() else { return }
        redoStack.append(editState)
        editState = previousState
        canUndo = !undoStack.isEmpty
        canRedo = true
        applyEditsDebounced()
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append(editState)
        editState = nextState
        canUndo = true
        canRedo = !redoStack.isEmpty
        applyEditsDebounced()
    }

    // MARK: - Reset

    func resetEdits() {
        pushUndo()
        editState.reset()
        applyEditsDebounced()
    }

    func clearImage() {
        originalImage = nil
        editedImage = nil
        originalCIImage = nil
        proxyCIImage = nil
        editState = EditState()
        presetThumbnails = [:]
        undoStack = []
        redoStack = []
        canUndo = false
        canRedo = false
    }
}

enum EditorTool: String, CaseIterable, Sendable {
    case presets
    case adjust
    case effects
    case crop

    nonisolated var displayName: String {
        switch self {
        case .presets: return "Presets"
        case .adjust: return "Ajustes"
        case .effects: return "Efectos"
        case .crop: return "Recortar"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .presets: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .effects: return "sparkles"
        case .crop: return "crop"
        }
    }
}
