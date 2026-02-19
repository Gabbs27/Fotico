import SwiftUI
@preconcurrency import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    @Published var processedPreviewCIImage: CIImage?   // CIImage for MetalImageView (no CGImage!)
    @Published var capturedImage: UIImage?
    @Published var selectedCameraType: CameraType = CameraType.allTypes[0]
    @Published var showEditor = false
    @Published var isCapturing = false
    @Published var showFlashOverlay = false

    // Toolbar state
    @Published var gridMode: GridMode = .off
    @Published var grainLevel: GrainLevel = .off
    @Published var toolbarLightLeakOn: Bool = false
    @Published var toolbarVignetteOn: Bool = false
    @Published var toolbarBloomOn: Bool = false
    @Published var selectedToolbarTab: CameraToolbarTab? = nil

    let cameraService = CameraService()

    private let ciContext: CIContext
    private let processingQueue = DispatchQueue(label: "com.lume.processing", qos: .userInitiated)
    private var previewCancellable: AnyCancellable?

    // Semaphore-based frame dropping: if GPU is busy, drop the frame.
    // Value of 1 = at most one preview frame being processed at a time.
    private let frameSemaphore = DispatchSemaphore(value: 1)

    init() {
        self.ciContext = RenderEngine.shared.cameraContext
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
                self.processPreviewFrame(ciImage)
            }
    }

    func stopCamera() {
        previewCancellable?.cancel()
        cameraService.stopSession()
    }

    // MARK: - Live Preview Processing (semaphore-gated)
    //
    // Uses semaphore instead of frame skip counter:
    // - If processing slot is free -> process this frame
    // - If still processing previous frame -> drop this frame
    // This adapts to GPU speed: fast GPU = no drops, slow GPU = drops excess frames.

    private func processPreviewFrame(_ ciImage: CIImage) {
        // Non-blocking check: if already processing, drop this frame
        guard frameSemaphore.wait(timeout: .now()) == .success else { return }

        let cameraType = selectedCameraType
        let extraGrain = grainLevel
        let fxLightLeak = toolbarLightLeakOn
        let fxVignette = toolbarVignetteOn
        let fxBloom = toolbarBloomOn

        let semaphore = frameSemaphore  // Capture before weak self
        processingQueue.async { [weak self] in
            guard let self else {
                semaphore.signal()  // Signal even if self is deallocated
                return
            }

            var result = ciImage

            // Downscale preview for faster processing
            let extent = result.extent
            let maxDim = max(extent.width, extent.height)
            if maxDim > CameraFilters.previewMaxDimension {
                let scale = CameraFilters.previewMaxDimension / maxDim
                result = result.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }

            // Apply LUT
            if let lutFileName = cameraType.lutFileName {
                result = CameraFilters.applyLivePreset(lutFileName: lutFileName, to: result)
            }

            // Apply grain: camera type default + toolbar override
            let grainAmount = max(cameraType.grainIntensity * CameraFilters.grainScaleFactor, extraGrain.intensity)
            if grainAmount > 0 {
                result = CameraFilters.addFilmGrain(to: result, intensity: CGFloat(grainAmount))
            }

            // Apply vignette: toolbar toggle or camera type default
            let vignetteAmount = fxVignette ? CameraFilters.toolbarVignetteIntensity : cameraType.vignetteIntensity
            if vignetteAmount > 0 {
                result = CameraFilters.addVignette(to: result, intensity: CGFloat(vignetteAmount))
            }

            // Apply bloom
            let bloomAmount = fxBloom ? CameraFilters.toolbarBloomIntensity : cameraType.bloomIntensity
            if bloomAmount > 0 {
                result = CameraFilters.addBloom(to: result, intensity: CGFloat(bloomAmount))
            }

            // Apply light leak
            if cameraType.lightLeakEnabled || fxLightLeak {
                result = CameraFilters.addLightLeak(to: result, intensity: CameraFilters.lightLeakIntensity)
            }

            // Pass CIImage directly -- MetalImageView will render it on GPU
            // No createCGImage needed!
            let finalImage = result

            DispatchQueue.main.async { [weak self] in
                self?.processedPreviewCIImage = finalImage
                semaphore.signal()  // Use captured semaphore, not self?.frameSemaphore
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
        let flashMode = cameraService.flashMode
        let cameraType = selectedCameraType
        let extraGrain = grainLevel
        let fxLightLeak = toolbarLightLeakOn
        let fxVignette = toolbarVignetteOn
        let fxBloom = toolbarBloomOn
        let context = ciContext

        let processed: UIImage = await withCheckedContinuation { continuation in
            processingQueue.async {
                let result: UIImage
                if flashMode == .vintage {
                    result = CameraFilters.vintageFlashProcess(
                        photo, cameraType: cameraType,
                        grainLevel: extraGrain, fxLightLeak: fxLightLeak,
                        fxVignette: fxVignette, fxBloom: fxBloom,
                        context: context
                    )
                } else {
                    result = CameraFilters.standardProcess(
                        photo, cameraType: cameraType,
                        grainLevel: extraGrain, fxLightLeak: fxLightLeak,
                        fxVignette: fxVignette, fxBloom: fxBloom,
                        context: context
                    )
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

    func selectCameraType(_ type: CameraType) {
        selectedCameraType = type
    }
}

// MARK: - Camera Filters (nonisolated, thread-safe)

/// Extracted filter processing to a separate enum to avoid @MainActor inheritance.
/// All methods are safe to call from any thread.
/// Uses fresh filter instances per call -- CIFilter is NOT thread-safe.
enum CameraFilters {

    // MARK: - Constants

    static let previewMaxDimension: CGFloat = 900
    static let grainScaleFactor: Double = 0.15
    static let toolbarVignetteIntensity: Double = 1.2
    static let toolbarBloomIntensity: Double = 0.3
    static let lightLeakIntensity: CGFloat = 0.4
    static let bloomRadius: Double = 10.0

    static func applyLivePreset(lutFileName: String, to image: CIImage) -> CIImage {
        return LUTService.shared.applyLUT(named: lutFileName, to: image, intensity: 1.0)
    }

    static func addVignette(to image: CIImage, intensity: CGFloat) -> CIImage {
        let vignette = CIFilter(name: "CIVignette")!
        vignette.setValue(image, forKey: kCIInputImageKey)
        vignette.setValue(intensity, forKey: kCIInputIntensityKey)
        vignette.setValue(max(intensity * 0.8, 1.0), forKey: kCIInputRadiusKey)
        return vignette.outputImage ?? image
    }

    static func addBloom(to image: CIImage, intensity: CGFloat) -> CIImage {
        let extent = image.extent
        let bloom = CIFilter(name: "CIBloom")!
        bloom.setValue(image, forKey: kCIInputImageKey)
        bloom.setValue(intensity, forKey: kCIInputIntensityKey)
        bloom.setValue(bloomRadius, forKey: kCIInputRadiusKey)
        return bloom.outputImage?.cropped(to: extent) ?? image
    }

    static func addLightLeak(to image: CIImage, intensity: CGFloat) -> CIImage {
        let extent = image.extent

        // Create a warm radial gradient for light leak effect
        let center = CIVector(x: extent.width * 0.8, y: extent.height * 0.7)
        let gradient = CIFilter(name: "CIRadialGradient")!
        gradient.setValue(center, forKey: "inputCenter")
        gradient.setValue(0, forKey: "inputRadius0")
        gradient.setValue(extent.width * 0.6, forKey: "inputRadius1")
        gradient.setValue(CIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: intensity), forKey: "inputColor0")
        gradient.setValue(CIColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 0), forKey: "inputColor1")

        guard let leak = gradient.outputImage?.cropped(to: extent) else { return image }

        let blend = CIFilter(name: "CIScreenBlendMode")!
        blend.setValue(image, forKey: kCIInputBackgroundImageKey)
        blend.setValue(leak, forKey: kCIInputImageKey)
        return blend.outputImage ?? image
    }

    static func vintageFlashProcess(
        _ image: UIImage,
        cameraType: CameraType,
        grainLevel: GrainLevel,
        fxLightLeak: Bool,
        fxVignette: Bool,
        fxBloom: Bool,
        context: CIContext
    ) -> UIImage {
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
        result = addVignette(to: result, intensity: 1.8)

        // 5. Grain
        let grainAmount = max(cameraType.grainIntensity * grainScaleFactor, grainLevel.intensity)
        if grainAmount > 0 {
            result = addFilmGrain(to: result, intensity: CGFloat(max(grainAmount, 0.06)))
        } else {
            result = addFilmGrain(to: result, intensity: 0.06)
        }

        // 6. Camera type LUT
        if let lutFileName = cameraType.lutFileName {
            result = LUTService.shared.applyLUT(named: lutFileName, to: result, intensity: 1.0)
        }

        // 7. Additional FX from toolbar
        let vignetteAmount = fxVignette ? toolbarVignetteIntensity : 0.0
        if vignetteAmount > 0 {
            result = addVignette(to: result, intensity: CGFloat(vignetteAmount))
        }

        let bloomAmount = fxBloom ? toolbarBloomIntensity : cameraType.bloomIntensity
        if bloomAmount > 0 {
            result = addBloom(to: result, intensity: CGFloat(bloomAmount))
        }

        if cameraType.lightLeakEnabled || fxLightLeak {
            result = addLightLeak(to: result, intensity: lightLeakIntensity)
        }

        return result.toUIImage(context: context) ?? image
    }

    static func standardProcess(
        _ image: UIImage,
        cameraType: CameraType,
        grainLevel: GrainLevel,
        fxLightLeak: Bool,
        fxVignette: Bool,
        fxBloom: Bool,
        context: CIContext
    ) -> UIImage {
        guard let ciImage = image.toCIImage() else { return image }
        var result = ciImage

        // Apply LUT
        if let lutFileName = cameraType.lutFileName {
            result = LUTService.shared.applyLUT(named: lutFileName, to: result, intensity: 1.0)
        }

        // Apply grain: camera type default + toolbar override
        let grainAmount = max(cameraType.grainIntensity * grainScaleFactor, grainLevel.intensity)
        if grainAmount > 0 {
            result = addFilmGrain(to: result, intensity: CGFloat(grainAmount))
        }

        // Apply vignette: toolbar toggle or camera type default
        let vignetteAmount = fxVignette ? toolbarVignetteIntensity : cameraType.vignetteIntensity
        if vignetteAmount > 0 {
            result = addVignette(to: result, intensity: CGFloat(vignetteAmount))
        }

        // Apply bloom
        let bloomAmount = fxBloom ? toolbarBloomIntensity : cameraType.bloomIntensity
        if bloomAmount > 0 {
            result = addBloom(to: result, intensity: CGFloat(bloomAmount))
        }

        // Apply light leak
        if cameraType.lightLeakEnabled || fxLightLeak {
            result = addLightLeak(to: result, intensity: lightLeakIntensity)
        }

        return result.toUIImage(context: context) ?? image
    }

    /// Adds film grain scaled to a reference resolution (2000px) so it looks
    /// the same whether the image is 900px preview or 4032px full-res.
    static func addFilmGrain(to image: CIImage, intensity: CGFloat) -> CIImage {
        let extent = image.extent

        // Fresh instances per call -- CIFilter is NOT thread-safe
        let noise = CIFilter(name: "CIRandomGenerator")!
        guard let rawNoise = noise.outputImage else { return image }

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

        let matrix = CIFilter(name: "CIColorMatrix")!
        matrix.setValue(scaledNoise, forKey: kCIInputImageKey)
        matrix.setValue(CIVector(x: intensity, y: 0, z: 0, w: 0), forKey: "inputRVector")
        matrix.setValue(CIVector(x: 0, y: intensity, z: 0, w: 0), forKey: "inputGVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: intensity, w: 0), forKey: "inputBVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        matrix.setValue(CIVector(x: -intensity/2, y: -intensity/2, z: -intensity/2, w: 0), forKey: "inputBiasVector")
        guard let grayNoise = matrix.outputImage else { return image }

        let add = CIFilter(name: "CIAdditionCompositing")!
        add.setValue(grayNoise, forKey: kCIInputImageKey)
        add.setValue(image, forKey: kCIInputBackgroundImageKey)
        return add.outputImage ?? image
    }
}
