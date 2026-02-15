import SwiftUI
import CoreImage
import Combine

@MainActor
class PhotoEditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var editedCIImage: CIImage?         // CIImage for MetalImageView (no CGImage creation!)
    @Published var editedImage: UIImage?            // UIImage fallback for export preview
    @Published var editState = EditState()
    @Published var isProcessing = false
    @Published var presetThumbnails: [String: UIImage] = [:]
    @Published var currentTool: EditorTool = .presets
    @Published var showExportSheet = false
    @Published var showImagePicker = false
    @Published var errorMessage: String?
    @Published var exportSuccess = false

    private let filterService = ImageFilterService()
    private var originalCIImage: CIImage?
    private var proxyCIImage: CIImage?       // Downscaled for live editing

    // Render coalescing: only the LATEST edit state renders.
    // While a render is in-flight, new requests queue up and only the last one executes.
    private var isRendering = false
    private var pendingRender = false
    private let renderQueue = DispatchQueue(label: "com.east.render", qos: .userInteractive)
    private let exportQueue = DispatchQueue(label: "com.east.export", qos: .userInitiated)

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
        }
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

        // Build lazy CIImage pipeline on background thread
        renderQueue.async { [weak self] in
            let result = service.applyEdits(
                to: proxyImage,
                state: state,
                presets: FilterPreset.allPresets
            )

            Task { @MainActor [weak self] in
                guard let self else { return }
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

    // MARK: - Thumbnails (concurrent generation)

    private func generatePresetThumbnails() {
        guard let ciImage = originalCIImage else { return }
        let allPresets = FilterPreset.allPresets

        Task {
            let thumbnails = await withCheckedContinuation { (continuation: CheckedContinuation<[String: UIImage], Never>) in
                let thumbnailSize = CGSize(width: 80, height: 80)
                // Use thread-safe wrapper to collect results
                let collector = ThumbnailCollector()
                let group = DispatchGroup()

                for preset in allPresets {
                    group.enter()
                    DispatchQueue.global(qos: .utility).async {
                        // Each thread gets its own ImageFilterService instance
                        // because CIFilter is NOT thread-safe
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
            self.presetThumbnails = thumbnails
        }
    }

    // MARK: - Export (full resolution, separate queue)

    func exportImage() async {
        guard let fullImage = originalCIImage else { return }
        isProcessing = true

        let state = editState
        let service = filterService
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
