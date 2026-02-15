import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

enum CameraMode: String, CaseIterable, Sendable {
    case normal
    case film

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .film: return "Film"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "camera"
        case .film: return "film"
        }
    }
}

@MainActor
class CameraViewModel: ObservableObject {
    @Published var processedPreviewImage: UIImage?
    @Published var capturedImage: UIImage?
    @Published var selectedPreset: FilterPreset? = FilterPreset.allPresets.first
    @Published var showEditor = false
    @Published var isCapturing = false
    @Published var showFlashOverlay = false
    @Published var grainOnPreview = false
    @Published var cameraMode: CameraMode = .film

    let cameraService = CameraService()

    private let ciContext: CIContext
    private let processingQueue = DispatchQueue(label: "com.east.processing", qos: .userInitiated)
    private var previewCancellable: AnyCancellable?
    private var frameSkipCounter = 0
    private var isProcessingPreview = false

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: device)
        } else {
            self.ciContext = CIContext()
        }
    }

    // MARK: - Lifecycle

    func startCamera() async {
        await cameraService.requestPermission()
        guard cameraService.permissionGranted else { return }
        cameraService.setupSession()
        cameraService.startSession()

        previewCancellable = cameraService.$previewCIImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ciImage in
                guard let self, let ciImage else { return }
                self.frameSkipCounter += 1
                guard self.frameSkipCounter % 3 == 0, !self.isProcessingPreview else { return }
                self.processPreviewFrame(ciImage)
            }
    }

    func stopCamera() {
        previewCancellable?.cancel()
        cameraService.stopSession()
    }

    // MARK: - Live Preview Processing (off main thread)

    private func processPreviewFrame(_ ciImage: CIImage) {
        isProcessingPreview = true
        let mode = cameraMode
        let preset = selectedPreset
        let grain = grainOnPreview
        let ctx = ciContext

        processingQueue.async { [weak self] in
            var result = ciImage

            // Downscale preview for faster processing
            let extent = result.extent
            let maxDim = max(extent.width, extent.height)
            if maxDim > 900 {
                let scale = 900.0 / maxDim
                result = result.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }

            if mode == .film {
                if let preset {
                    result = CameraFilters.applyLivePreset(preset, to: result)
                }
                if grain {
                    result = CameraFilters.addFilmGrain(to: result, intensity: 0.04)
                }
            }

            guard let cgImage = ctx.createCGImage(result, from: result.extent) else {
                DispatchQueue.main.async { [weak self] in self?.isProcessingPreview = false }
                return
            }
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async { [weak self] in
                self?.processedPreviewImage = uiImage
                self?.isProcessingPreview = false
            }
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() async {
        isCapturing = true
        HapticManager.impact(.medium)

        if cameraService.flashMode != .off {
            showFlashOverlay = true
        }

        guard let photo = await cameraService.capturePhoto() else {
            isCapturing = false
            showFlashOverlay = false
            return
        }

        // Move heavy processing off main thread
        let mode = cameraMode
        let flashMode = cameraService.flashMode
        let preset = selectedPreset
        let context = ciContext
        let grain = grainOnPreview

        let processed: UIImage = await withCheckedContinuation { continuation in
            processingQueue.async {
                let result: UIImage
                if mode == .normal {
                    result = photo
                } else if flashMode == .vintage {
                    result = CameraFilters.vintageFlashProcess(photo, preset: preset, shouldApplyGrain: grain, context: context)
                } else {
                    result = CameraFilters.standardProcess(photo, preset: preset, context: context, shouldApplyGrain: grain)
                }
                continuation.resume(returning: result)
            }
        }

        capturedImage = processed
        isCapturing = false
        showFlashOverlay = false
        showEditor = true
    }

    // MARK: - Controls

    func selectPreset(_ preset: FilterPreset?) {
        guard let preset else {
            selectedPreset = nil
            return
        }
        if selectedPreset?.id == preset.id {
            selectedPreset = nil
        } else {
            selectedPreset = preset
        }
    }

    func toggleMode() {
        cameraMode = cameraMode == .normal ? .film : .normal
        if cameraMode == .normal {
            selectedPreset = nil
        }
        grainOnPreview = false
        HapticManager.selection()
    }
}

// MARK: - Camera Filters (nonisolated, thread-safe)

/// Extracted filter processing to a separate enum to avoid @MainActor inheritance.
/// All methods are safe to call from any thread.
enum CameraFilters {
    static func applyLivePreset(_ preset: FilterPreset, to image: CIImage) -> CIImage {
        if let filterName = preset.ciFilterName {
            guard let filter = CIFilter(name: filterName) else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage ?? image
        }
        switch preset.id {
        case "east_cine":
            let temp = CIFilter(name: "CITemperatureAndTint")!
            temp.setValue(image, forKey: kCIInputImageKey)
            temp.setValue(CIVector(x: 5500, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 7000, y: -20), forKey: "inputTargetNeutral")
            return temp.outputImage ?? image
        case "east_retro":
            let color = CIFilter(name: "CIColorControls")!
            color.setValue(image, forKey: kCIInputImageKey)
            color.setValue(0.6, forKey: kCIInputSaturationKey)
            color.setValue(0.03, forKey: kCIInputBrightnessKey)
            return color.outputImage ?? image
        default:
            return image
        }
    }

    static func vintageFlashProcess(_ image: UIImage, preset: FilterPreset?, shouldApplyGrain: Bool, context: CIContext) -> UIImage {
        guard let ciImage = image.toCIImage() else { return image }
        var result = ciImage

        // 1. Warm color cast
        let warmMatrix = CIFilter(name: "CIColorMatrix")!
        warmMatrix.setValue(result, forKey: kCIInputImageKey)
        warmMatrix.setValue(CIVector(x: 1.15, y: 0, z: 0, w: 0), forKey: "inputRVector")
        warmMatrix.setValue(CIVector(x: 0, y: 1.08, z: 0, w: 0), forKey: "inputGVector")
        warmMatrix.setValue(CIVector(x: 0, y: 0, z: 0.78, w: 0), forKey: "inputBVector")
        warmMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        result = warmMatrix.outputImage ?? result

        // 2. Overexposure
        let exposure = CIFilter(name: "CIExposureAdjust")!
        exposure.setValue(result, forKey: kCIInputImageKey)
        exposure.setValue(0.4, forKey: kCIInputEVKey)
        result = exposure.outputImage ?? result

        // 3. Faded look
        let color = CIFilter(name: "CIColorControls")!
        color.setValue(result, forKey: kCIInputImageKey)
        color.setValue(0.75, forKey: kCIInputSaturationKey)
        color.setValue(0.9, forKey: kCIInputContrastKey)
        result = color.outputImage ?? result

        // 4. Heavy vignette
        let vignette = CIFilter(name: "CIVignette")!
        vignette.setValue(result, forKey: kCIInputImageKey)
        vignette.setValue(1.8, forKey: kCIInputIntensityKey)
        vignette.setValue(1.2, forKey: kCIInputRadiusKey)
        result = vignette.outputImage ?? result

        // 5. Grain
        if shouldApplyGrain {
            result = addFilmGrain(to: result, intensity: 0.06)
        }

        // 6. Preset
        if let preset, let filterName = preset.ciFilterName {
            let f = CIFilter(name: filterName)!
            f.setValue(result, forKey: kCIInputImageKey)
            result = f.outputImage ?? result
        }

        return result.toUIImage(context: context) ?? image
    }

    static func standardProcess(_ image: UIImage, preset: FilterPreset?, context: CIContext, shouldApplyGrain: Bool) -> UIImage {
        guard let ciImage = image.toCIImage() else { return image }
        var result = ciImage

        if let preset, let filterName = preset.ciFilterName {
            let f = CIFilter(name: filterName)!
            f.setValue(result, forKey: kCIInputImageKey)
            result = f.outputImage ?? result
        }

        if shouldApplyGrain {
            result = addFilmGrain(to: result, intensity: 0.04)
        }
        return result.toUIImage(context: context) ?? image
    }

    /// Adds film grain scaled to a reference resolution (2000px) so it looks
    /// the same whether the image is 900px preview or 4032px full-res.
    static func addFilmGrain(to image: CIImage, intensity: CGFloat) -> CIImage {
        let extent = image.extent
        let noiseFilter = CIFilter(name: "CIRandomGenerator")!
        guard let rawNoise = noiseFilter.outputImage else { return image }

        // Scale noise to match a reference resolution of ~2000px
        let referenceSize: CGFloat = 2000.0
        let maxDim = max(extent.width, extent.height)
        let noiseScale = maxDim / referenceSize

        var scaledNoise: CIImage
        if noiseScale > 0.1 {
            scaledNoise = rawNoise.transformed(by: CGAffineTransform(scaleX: noiseScale, y: noiseScale))
        } else {
            scaledNoise = rawNoise
        }
        scaledNoise = scaledNoise.cropped(to: extent)

        let gray = CIFilter(name: "CIColorMatrix")!
        gray.setValue(scaledNoise, forKey: kCIInputImageKey)
        gray.setValue(CIVector(x: intensity, y: 0, z: 0, w: 0), forKey: "inputRVector")
        gray.setValue(CIVector(x: 0, y: intensity, z: 0, w: 0), forKey: "inputGVector")
        gray.setValue(CIVector(x: 0, y: 0, z: intensity, w: 0), forKey: "inputBVector")
        gray.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        gray.setValue(CIVector(x: -intensity/2, y: -intensity/2, z: -intensity/2, w: 0), forKey: "inputBiasVector")
        guard let grayNoise = gray.outputImage else { return image }

        let blend = CIFilter(name: "CIAdditionCompositing")!
        blend.setValue(grayNoise, forKey: kCIInputImageKey)
        blend.setValue(image, forKey: kCIInputBackgroundImageKey)
        return blend.outputImage ?? image
    }
}
