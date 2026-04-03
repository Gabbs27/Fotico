import SwiftUI
import SwiftData
import CoreImage
import Combine

@MainActor
@Observable class PhotoEditorViewModel {
    var originalImage: UIImage?
    var editedCIImage: CIImage?         // CIImage for MetalImageView (no CGImage creation!)
    var editedImage: UIImage?            // UIImage fallback for export preview
    var editState = EditState()
    var isProcessing = false
    var presetThumbnails: [String: UIImage] = [:]
    var currentTool: EditorTool = .presets
    var errorMessage: String?
    var exportSuccess = false
    var showSaveProjectSheet = false
    var isMaskPainting: Bool = false
    var maskBrushMode: MaskBrushMode = .brush
    var maskBrushSize: CGFloat = 40.0

    enum MaskBrushMode {
        case brush   // paints white (apply effect)
        case eraser  // paints black (remove effect)
    }

    // Separate filter service per queue — CIFilter is NOT thread-safe
    private let filterService = ImageFilterService()       // For renderQueue only
    private let exportFilterService = ImageFilterService() // For exportQueue only
    private var originalCIImage: CIImage?
    private var proxyCIImage: CIImage?       // Downscaled for live editing

    // Render coalescing: only the LATEST edit state renders.
    // While a render is in-flight, new requests queue up and only the last one executes.
    private var isRendering = false
    private var pendingRender = false
    private var renderGeneration = 0  // Incremented on clearImage to invalidate in-flight renders
    private let renderQueue = DispatchQueue(label: "com.lume.render", qos: .userInteractive)
    private let exportQueue = DispatchQueue(label: "com.lume.export", qos: .userInitiated)
    private var thumbnailTask: Task<Void, Never>?

    // Undo/Redo
    private var undoStack: [EditState] = []
    private var redoStack: [EditState] = []
    var canUndo = false
    var canRedo = false

    var hasImage: Bool { originalImage != nil }

    // MARK: - Image Loading

    func loadImage(_ image: UIImage) {
        originalImage = image
        originalCIImage = image.toCIImage()

        // Create materialized proxy — render to CVPixelBuffer so the downscale
        // is computed once, not re-evaluated on every filter pass.
        if let ciImage = originalCIImage {
            proxyCIImage = Self.createMaterializedProxy(from: ciImage)
        }

        editState = EditState()
        undoStack = []
        redoStack = []
        canUndo = false
        canRedo = false
        editedImage = image
        editedCIImage = originalCIImage
        generatePresetThumbnails()
    }

    /// Creates a downscaled proxy and materializes it to a CVPixelBuffer.
    /// Without materialization, the downscale transform is re-evaluated on every render.
    nonisolated private static func createMaterializedProxy(from ciImage: CIImage) -> CIImage {
        let extent = ciImage.extent
        let maxDim = max(extent.width, extent.height)
        if maxDim <= 1200 { return ciImage }
        let scale = 1200.0 / maxDim

        // Use CILanczosScaleTransform for highest quality downscale
        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            return ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }
        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        guard let scaled = scaleFilter.outputImage else {
            return ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        // Materialize to CVPixelBuffer — prevents re-computation on every edit
        let proxySize = scaled.extent.size
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any],
        ]
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(proxySize.width), Int(proxySize.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )

        if let pb = pixelBuffer {
            RenderEngine.shared.context.render(scaled, to: pb)
            return CIImage(cvPixelBuffer: pb)
        }
        return scaled
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
        requestRender()
    }

    func deselectPreset() {
        pushUndo()
        editState.selectedPresetId = nil
        editState.presetIntensity = 1.0
        requestRender()
    }

    func updatePresetIntensity(_ intensity: Double) {
        editState.presetIntensity = intensity
        requestRender()
    }

    // MARK: - Adjustments

    func updateAdjustment() {
        requestRender()
    }

    func commitAdjustment() {
        pushUndo()
    }

    // MARK: - Crop & Rotation

    func updateRotation(_ degrees: Double) {
        editState.rotation = degrees
        requestRender()
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
        case .dust: editState.dustIntensity = intensity
        case .halation: editState.halationIntensity = intensity
        case .chromaticAberration: editState.chromaticAberrationIntensity = intensity
        case .filmBurn: editState.filmBurnIntensity = intensity
        case .softDiffusion: editState.softDiffusionIntensity = intensity
        case .letterbox: editState.letterboxIntensity = intensity
        case .motionBlur: editState.motionBlurIntensity = intensity
        case .filmBlur: editState.filmBlurIntensity = intensity
        case .lowRes: editState.lowResIntensity = intensity
        }
        requestRender()
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
        case .dust: return editState.dustIntensity
        case .halation: return editState.halationIntensity
        case .chromaticAberration: return editState.chromaticAberrationIntensity
        case .filmBurn: return editState.filmBurnIntensity
        case .softDiffusion: return editState.softDiffusionIntensity
        case .letterbox: return editState.letterboxIntensity
        case .motionBlur: return editState.motionBlurIntensity
        case .filmBlur: return editState.filmBlurIntensity
        case .lowRes: return editState.lowResIntensity
        }
    }

    // MARK: - Overlays

    func selectOverlay(_ overlayId: String?) {
        pushUndo()
        if editState.overlayId == overlayId {
            editState.overlayId = nil
        } else {
            editState.overlayId = overlayId
        }
        requestRender()
    }

    func updateOverlayIntensity(_ intensity: Double) {
        editState.overlayIntensity = intensity
        requestRender()
    }

    func commitOverlayChange() {
        pushUndo()
    }

    // MARK: - Motion Blur Mask

    func updateMotionBlurAngle(_ angle: Double) {
        pushUndo()
        editState.motionBlurAngle = angle
        requestRender()
    }

    func toggleMotionBlurMask() {
        pushUndo()
        editState.motionBlurMaskEnabled.toggle()
        requestRender()
    }

    func updateMotionBlurMask(_ maskData: Data?) {
        editState.motionBlurMask = maskData
        requestRender()
    }

    func toggleMotionBlurMaskInvert() {
        pushUndo()
        editState.motionBlurMaskInverted.toggle()
        requestRender()
    }

    func clearMotionBlurMask() {
        pushUndo()
        editState.motionBlurMask = nil
        editState.motionBlurMaskEnabled = false
        editState.motionBlurMaskInverted = false
        requestRender()
    }

    var proxyImageSize: CGSize {
        guard let proxy = proxyCIImage else {
            return editedCIImage?.extent.size ?? .zero
        }
        return proxy.extent.size
    }

    // MARK: - Text Layers

    func addTextLayer() {
        pushUndo()
        let layer = TextLayer(id: UUID().uuidString)
        editState.textLayers.append(layer)
        requestRender()
    }

    func updateTextLayer(_ layer: TextLayer) {
        guard let index = editState.textLayers.firstIndex(where: { $0.id == layer.id }) else { return }
        editState.textLayers[index] = layer
        requestRender()
    }

    func removeTextLayer(_ layerId: String) {
        pushUndo()
        editState.textLayers.removeAll { $0.id == layerId }
        requestRender()
    }

    func commitTextChange() {
        pushUndo()
    }

    // MARK: - Copy/Paste Edits (Batch Editing)

    func copyEdits() {
        EditClipboard.shared.copy(editState)
    }

    func pasteEdits() {
        guard let copied = EditClipboard.shared.copiedState else { return }
        pushUndo()
        editState = copied
        requestRender()
        HapticManager.notification(.success)
    }

    // MARK: - Rendering (Coalescing Throttle)
    //
    // Instead of debounce (which adds latency), we use a coalescing pattern:
    // - At most one render in flight at a time
    // - If a new request comes while rendering, it's marked as pending
    // - When the current render finishes, the pending render executes with the LATEST state
    // This guarantees: (a) max one render in flight, (b) latest state always renders, (c) no delay

    private func requestRender() {
        if isRendering {
            pendingRender = true
            return
        }
        executeRender()
    }

    private func executeRender() {
        guard let proxyImage = proxyCIImage else { return }
        isRendering = true
        isProcessing = true

        let state = editState
        let service = filterService
        let generation = renderGeneration  // Capture current generation

        // Build lazy CIImage pipeline on background thread
        renderQueue.async { [weak self] in
            let result = service.applyEdits(
                to: proxyImage,
                state: state,
                presets: FilterPreset.allPresets
            )

            Task { @MainActor [weak self] in
                guard let self else { return }

                // If clearImage() was called during render, discard the result
                guard self.renderGeneration == generation else {
                    self.isRendering = false
                    self.isProcessing = false
                    return
                }

                // Update CIImage directly — MetalImageView renders it without CGImage conversion
                self.editedCIImage = result
                self.isProcessing = false
                self.isRendering = false

                // If a new request came in during render, execute it now
                if self.pendingRender {
                    self.pendingRender = false
                    self.executeRender()
                }
            }
        }
    }

    // MARK: - Thumbnails (bounded concurrent generation)

    private static let thumbnailQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.lume.thumbnails"
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .utility
        return queue
    }()

    private func generatePresetThumbnails() {
        guard let ciImage = originalCIImage else { return }
        let allPresets = FilterPreset.allPresets

        thumbnailTask?.cancel()
        thumbnailTask = Task { [weak self] in
            let thumbnails = await withCheckedContinuation { (continuation: CheckedContinuation<[String: UIImage], Never>) in
                let thumbnailSize = CGSize(width: 80, height: 80)
                let collector = ThumbnailCollector()
                let group = DispatchGroup()

                for preset in allPresets {
                    group.enter()
                    Self.thumbnailQueue.addOperation {
                        let threadService = ImageFilterService()
                        if let thumbnail = threadService.generateThumbnail(
                            from: ciImage,
                            preset: preset,
                            size: thumbnailSize
                        ) {
                            collector.set(preset.id, thumbnail: thumbnail)
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    continuation.resume(returning: collector.results)
                }
            }
            guard !Task.isCancelled else { return }
            self?.presetThumbnails = thumbnails
        }
    }

    // MARK: - Export (full resolution, separate queue)

    func exportImage() async {
        guard let fullImage = originalCIImage else { return }
        isProcessing = true

        let state = editState
        let service = exportFilterService  // Dedicated instance for export queue
        let queue = exportQueue

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
            let libraryService = PhotoLibraryService()
            try await libraryService.saveToPhotoLibrary(exportImage)
            exportSuccess = true
            HapticManager.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }

        isProcessing = false
    }

    // MARK: - Save Project

    func saveAsProject(name: String, modelContext: ModelContext) {
        guard let image = originalImage else { return }

        let projectId = UUID().uuidString
        let imagePath: String
        do {
            imagePath = try ProjectStorageService.shared.saveOriginalImage(image, projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        guard let editStateData = try? JSONEncoder().encode(editState) else {
            errorMessage = "No se pudo guardar el estado de edición"
            return
        }
        let project = PhotoProject(name: name, originalImagePath: imagePath, editStateData: editStateData)
        project.thumbnailData = ProjectStorageService.shared.generateThumbnail(image)
        modelContext.insert(project)
        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            errorMessage = "Error al guardar el proyecto"
        }
    }

    // MARK: - Undo/Redo

    private static let maxUndoStackSize = 50

    private func pushUndo() {
        undoStack.append(editState)
        // Cap undo stack to prevent unbounded memory growth
        if undoStack.count > Self.maxUndoStackSize {
            undoStack.removeFirst(undoStack.count - Self.maxUndoStackSize)
        }
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
        requestRender()
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append(editState)
        editState = nextState
        canUndo = true
        canRedo = !redoStack.isEmpty
        requestRender()
    }

    // MARK: - Reset

    func resetEdits() {
        pushUndo()
        editState.reset()
        requestRender()
    }

    func clearImage() {
        renderGeneration += 1  // Invalidate any in-flight renders
        isRendering = false
        pendingRender = false
        thumbnailTask?.cancel()
        thumbnailTask = nil
        originalImage = nil
        editedImage = nil
        editedCIImage = nil
        originalCIImage = nil
        proxyCIImage = nil
        editState = EditState()
        presetThumbnails = [:]
        undoStack = []
        redoStack = []
        canUndo = false
        canRedo = false
        RenderEngine.shared.clearCaches()
    }
}

/// Thread-safe thumbnail collector for concurrent generation
private final class ThumbnailCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var _results: [String: UIImage] = [:]

    var results: [String: UIImage] {
        lock.lock()
        defer { lock.unlock() }
        return _results
    }

    func set(_ key: String, thumbnail: UIImage) {
        lock.lock()
        _results[key] = thumbnail
        lock.unlock()
    }
}

enum EditorTool: String, CaseIterable, Sendable {
    case presets
    case adjust
    case effects
    case overlays
    case crop
    case colorTone
    case hsl
    case text

    var displayName: String {
        switch self {
        case .presets: return "Filtros"
        case .adjust: return "Ajustes"
        case .effects: return "Efectos"
        case .overlays: return "Texturas"
        case .crop: return "Rotar"
        case .colorTone: return "Tono"
        case .hsl: return "HSL"
        case .text: return "Texto"
        }
    }

    var icon: String {
        switch self {
        case .presets: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .effects: return "sparkles"
        case .overlays: return "square.on.square"
        case .crop: return "crop"
        case .colorTone: return "circle.lefthalf.filled"
        case .hsl: return "circle.hexagongrid"
        case .text: return "textformat"
        }
    }
}
