import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

/// Image filter pipeline using CIFilter chains for presets, adjustments, and effects.
/// Uses shared RenderEngine for GPU-accelerated rendering.
///
/// ⚠️ NOT thread-safe internally — CIFilter instances are mutable and reused.
/// Create ONE instance per serial DispatchQueue. Do NOT share across concurrent queues.
/// Marked @unchecked Sendable to allow capture in DispatchQueue closures — the caller
/// is responsible for ensuring single-queue access.
///
/// Performance optimizations:
/// - CIFilter instances cached and reused within one instance
/// - Identity filters skipped (no work for default parameter values)
/// - Color adjustments ordered first for kernel fusion (single GPU pass)
/// - Shared CIContext from RenderEngine (avoids ~50-100ms context creation)
class ImageFilterService: @unchecked Sendable {
    private let context: CIContext

    // MARK: - CIFilter instances (per-instance, NOT shared across threads)

    private let colorControlsFilter = CIFilter(name: "CIColorControls")!
    private let exposureFilter = CIFilter(name: "CIExposureAdjust")!
    private let temperatureFilter = CIFilter(name: "CITemperatureAndTint")!
    private let vibranceFilter = CIFilter(name: "CIVibrance")!
    private let sharpenFilter = CIFilter(name: "CISharpenLuminance")!
    private let vignetteFilter = CIFilter(name: "CIVignette")!
    private let bloomFilter = CIFilter(name: "CIBloom")!
    private let dissolveFilter = CIFilter(name: "CIDissolveTransition")!
    private let noiseFilter = CIFilter(name: "CIRandomGenerator")!
    private let colorMatrixFilter = CIFilter(name: "CIColorMatrix")!
    private let addCompFilter = CIFilter(name: "CIAdditionCompositing")!

    // Preset filter cache: [filterName: CIFilter]
    private var presetFilterCache: [String: CIFilter] = [:]

    init() {
        self.context = RenderEngine.shared.context
    }

    /// Get or create a cached CIFilter by name (NOT thread-safe — use one service per queue)
    private func cachedFilter(named name: String) -> CIFilter? {
        if let existing = presetFilterCache[name] {
            return existing
        }
        guard let filter = CIFilter(name: name) else { return nil }
        presetFilterCache[name] = filter
        return filter
    }

    // MARK: - Full Pipeline

    func applyEdits(to sourceImage: CIImage, state: EditState, presets: [FilterPreset]) -> CIImage {
        var image = sourceImage

        // 1. Apply rotation
        if state.rotation != 0 {
            let radians = state.rotation * .pi / 180.0
            let transform = CGAffineTransform(rotationAngle: radians)
            image = image.transformed(by: transform)
            let offset = image.extent.origin
            image = image.transformed(by: CGAffineTransform(translationX: -offset.x, y: -offset.y))
        }

        // 2. Apply crop
        if let crop = state.cropRect {
            let cropCGRect = CGRect(x: crop.x, y: crop.y, width: crop.width, height: crop.height)
            if !cropCGRect.isEmpty {
                image = image.cropped(to: cropCGRect)
                let cropOffset = image.extent.origin
                image = image.transformed(by: CGAffineTransform(translationX: -cropOffset.x, y: -cropOffset.y))
            }
        }

        // 3. Apply preset
        if let presetId = state.selectedPresetId,
           let preset = presets.first(where: { $0.id == presetId }) {
            image = applyPreset(preset, to: image, intensity: state.presetIntensity)
        }

        // 4. Apply basic adjustments (color filters first for kernel fusion)
        image = applyAdjustments(state, to: image)

        // 5. Apply effects (spatial filters after color for optimal fusion)
        image = applyEffects(state, to: image)

        // 5.5. Apply overlay (texture compositing)
        if let overlayId = state.overlayId {
            image = applyOverlay(overlayId, to: image, intensity: state.overlayIntensity)
        }

        // 6. Safety: ensure the result has a finite extent (CIRandomGenerator etc. produce infinite)
        let sourceExtent = sourceImage.extent
        if image.extent.isInfinite {
            image = image.cropped(to: sourceExtent)
        }

        return image
    }

    // MARK: - Presets

    func applyPreset(_ preset: FilterPreset, to image: CIImage, intensity: Double) -> CIImage {
        var filtered: CIImage

        if let lutFileName = preset.lutFileName {
            // LUT-based preset (Pro) — apply via CIColorCubeWithColorSpace
            filtered = LUTService.shared.applyLUT(named: lutFileName, to: image, intensity: 1.0)
        } else if let ciFilterName = preset.ciFilterName {
            filtered = applyStandardPreset(ciFilterName, to: image)
        } else {
            filtered = applyCustomPreset(preset, to: image)
        }

        // Apply additional preset parameters.
        // Collect all ColorControls params (brightness, contrast, saturation) and apply
        // them in a single call — applying individually resets the other values to defaults.
        filtered = applyPresetParameters(preset.parameters, to: filtered)

        // Blend with original based on intensity
        if intensity < 1.0 {
            filtered = blendImages(original: image, filtered: filtered, intensity: intensity)
        }

        return filtered
    }

    private func applyStandardPreset(_ filterName: String, to image: CIImage) -> CIImage {
        guard let filter = cachedFilter(named: filterName) else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    private func applyCustomPreset(_ preset: FilterPreset, to image: CIImage) -> CIImage {
        switch preset.id {
        case "fotico_cine":
            return applyCinematicGrade(to: image, preset: preset)
        case "fotico_retro":
            return applyRetroLook(to: image, preset: preset)
        default:
            return image
        }
    }

    private func applyCinematicGrade(to image: CIImage, preset: FilterPreset) -> CIImage {
        var result = image

        let contrastValue = preset.parameters.first(where: { $0.key == "contrast" })?.value ?? 1.2
        result = applyColorControls(to: result, brightness: 0, contrast: contrastValue, saturation: 1.0)

        guard let tempFilter = cachedFilter(named: "CITemperatureAndTint") else { return result }
        tempFilter.setValue(result, forKey: kCIInputImageKey)
        tempFilter.setValue(CIVector(x: 5500, y: 0), forKey: "inputNeutral")
        tempFilter.setValue(CIVector(x: 7000, y: -20), forKey: "inputTargetNeutral")
        result = tempFilter.outputImage ?? result

        return result
    }

    private func applyRetroLook(to image: CIImage, preset: FilterPreset) -> CIImage {
        var result = image

        let satValue = preset.parameters.first(where: { $0.key == "saturation" })?.value ?? 0.6
        result = applyColorControls(to: result, brightness: 0.03, contrast: 1.0, saturation: satValue)

        temperatureFilter.setValue(result, forKey: kCIInputImageKey)
        temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        temperatureFilter.setValue(CIVector(x: 7500, y: 0), forKey: "inputTargetNeutral")
        result = temperatureFilter.outputImage ?? result

        // Use a fresh vignette filter — the shared vignetteFilter is reserved for effects
        let retroVignette = CIFilter(name: "CIVignette")!
        retroVignette.setValue(result, forKey: kCIInputImageKey)
        retroVignette.setValue(1.0, forKey: kCIInputIntensityKey)
        retroVignette.setValue(1.5, forKey: kCIInputRadiusKey)
        result = retroVignette.outputImage ?? result

        return result
    }

    /// Applies preset parameters, batching ColorControls params (brightness, contrast,
    /// saturation) into a single CIColorControls call to avoid resetting each other.
    /// Also handles grain, vignette, temperature, and vibrance as separate filters.
    private func applyPresetParameters(_ parameters: [FilterParameter], to image: CIImage) -> CIImage {
        var result = image

        // Collect ColorControls values — default to identity values
        var brightness: Double = 0.0
        var contrast: Double = 1.0
        var saturation: Double = 1.0
        var hasColorControls = false

        for param in parameters {
            switch param.key {
            case "brightness":
                brightness = param.value
                hasColorControls = true
            case "contrast":
                contrast = param.value
                hasColorControls = true
            case "saturation":
                saturation = param.value
                hasColorControls = true
            case "temperature":
                temperatureFilter.setValue(result, forKey: kCIInputImageKey)
                temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                temperatureFilter.setValue(CIVector(x: param.value, y: 0), forKey: "inputTargetNeutral")
                result = temperatureFilter.outputImage ?? result
            case "vibrance":
                vibranceFilter.setValue(result, forKey: kCIInputImageKey)
                vibranceFilter.setValue(param.value, forKey: "inputAmount")
                result = vibranceFilter.outputImage ?? result
            case "vignette":
                // Use a separate vignette filter for presets to avoid conflict with effects vignette
                let presetVignette = CIFilter(name: "CIVignette")!
                presetVignette.setValue(result, forKey: kCIInputImageKey)
                presetVignette.setValue(param.value, forKey: kCIInputIntensityKey)
                presetVignette.setValue(1.5, forKey: kCIInputRadiusKey)
                result = presetVignette.outputImage ?? result
            case "grain":
                // Apply grain as part of the preset (e.g., Retro)
                result = applySimpleGrain(to: result, intensity: param.value, size: 0.5)
            default:
                break
            }
        }

        // Apply batched ColorControls in one pass
        if hasColorControls {
            result = applyColorControls(to: result, brightness: brightness, contrast: contrast, saturation: saturation)
        }

        return result
    }

    // MARK: - Adjustments

    func applyAdjustments(_ state: EditState, to image: CIImage) -> CIImage {
        var result = image

        if state.brightness != 0 || state.contrast != 1.0 || state.saturation != 1.0 {
            result = applyColorControls(
                to: result,
                brightness: state.brightness,
                contrast: state.contrast,
                saturation: state.saturation
            )
        }

        if state.exposure != 0 {
            exposureFilter.setValue(result, forKey: kCIInputImageKey)
            exposureFilter.setValue(state.exposure, forKey: kCIInputEVKey)
            result = exposureFilter.outputImage ?? result
        }

        if state.temperature != 6500 || state.tint != 0 {
            temperatureFilter.setValue(result, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temperatureFilter.setValue(CIVector(x: state.temperature, y: state.tint), forKey: "inputTargetNeutral")
            result = temperatureFilter.outputImage ?? result
        }

        if state.vibrance != 0 {
            vibranceFilter.setValue(result, forKey: kCIInputImageKey)
            vibranceFilter.setValue(state.vibrance, forKey: "inputAmount")
            result = vibranceFilter.outputImage ?? result
        }

        if state.sharpness > 0 {
            sharpenFilter.setValue(result, forKey: kCIInputImageKey)
            sharpenFilter.setValue(state.sharpness, forKey: kCIInputSharpnessKey)
            result = sharpenFilter.outputImage ?? result
        }

        return result
    }

    // MARK: - Effects

    func applyEffects(_ state: EditState, to image: CIImage) -> CIImage {
        var result = image
        let sourceExtent = image.extent

        if state.vignetteIntensity > 0 {
            vignetteFilter.setValue(result, forKey: kCIInputImageKey)
            vignetteFilter.setValue(state.vignetteIntensity, forKey: kCIInputIntensityKey)
            vignetteFilter.setValue(state.vignetteRadius, forKey: kCIInputRadiusKey)
            result = vignetteFilter.outputImage ?? result
        }

        if state.bloomIntensity > 0 {
            bloomFilter.setValue(result, forKey: kCIInputImageKey)
            bloomFilter.setValue(state.bloomIntensity, forKey: kCIInputIntensityKey)
            bloomFilter.setValue(state.bloomRadius, forKey: kCIInputRadiusKey)
            result = bloomFilter.outputImage?.cropped(to: sourceExtent) ?? result
        }

        if state.solarizeThreshold > 0 {
            // Solarize needs its own filter instance since colorControlsFilter might be reused
            let solarizeControls = CIFilter(name: "CIColorControls")!
            solarizeControls.setValue(result, forKey: kCIInputImageKey)
            solarizeControls.setValue(1.0 + state.solarizeThreshold, forKey: kCIInputContrastKey)
            solarizeControls.setValue(0.0, forKey: kCIInputBrightnessKey)
            solarizeControls.setValue(1.0, forKey: kCIInputSaturationKey)
            if let contrastImage = solarizeControls.outputImage {
                guard let invertFilter = cachedFilter(named: "CIColorInvert") else { return result }
                invertFilter.setValue(contrastImage, forKey: kCIInputImageKey)
                if let inverted = invertFilter.outputImage {
                    result = blendImages(original: result, filtered: inverted, intensity: state.solarizeThreshold)
                }
            }
        }

        if state.lightLeakIntensity > 0 {
            result = applyLightLeak(to: result, intensity: state.lightLeakIntensity)
        }

        if state.glitchIntensity > 0 {
            result = applyGlitch(to: result, intensity: state.glitchIntensity)
        }

        if state.fisheyeIntensity > 0 {
            result = applyFisheye(to: result, intensity: state.fisheyeIntensity)
        }

        if state.thresholdLevel > 0 {
            result = applyThreshold(to: result, level: state.thresholdLevel)
        }

        if state.grainIntensity > 0 {
            result = applySimpleGrain(to: result, intensity: state.grainIntensity, size: state.grainSize)
        }

        // Ensure finite extent
        if result.extent.isInfinite {
            result = result.cropped(to: sourceExtent)
        }

        return result
    }

    // MARK: - Glitch

    private func applyGlitch(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent
        let offsetAmount = intensity * 20.0

        let redF = CIFilter(name: "CIColorMatrix")!
        redF.setValue(image, forKey: kCIInputImageKey)
        redF.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        redF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        redF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        redF.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let redChannel = redF.outputImage?
            .transformed(by: CGAffineTransform(translationX: offsetAmount, y: 0))
            .cropped(to: extent) ?? image

        let greenF = CIFilter(name: "CIColorMatrix")!
        greenF.setValue(image, forKey: kCIInputImageKey)
        greenF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        greenF.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        greenF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        greenF.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let greenChannel = greenF.outputImage?.cropped(to: extent) ?? image

        let blueF = CIFilter(name: "CIColorMatrix")!
        blueF.setValue(image, forKey: kCIInputImageKey)
        blueF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blueF.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blueF.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        blueF.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let blueChannel = blueF.outputImage?
            .transformed(by: CGAffineTransform(translationX: -offsetAmount, y: offsetAmount * 0.3))
            .cropped(to: extent) ?? image

        let addRGFilter = CIFilter(name: "CIAdditionCompositing")!
        addRGFilter.setValue(redChannel, forKey: kCIInputImageKey)
        addRGFilter.setValue(greenChannel, forKey: kCIInputBackgroundImageKey)
        let rg = addRGFilter.outputImage ?? image

        let addRGBFilter = CIFilter(name: "CIAdditionCompositing")!
        addRGBFilter.setValue(blueChannel, forKey: kCIInputImageKey)
        addRGBFilter.setValue(rg, forKey: kCIInputBackgroundImageKey)
        let glitched = addRGBFilter.outputImage?.cropped(to: extent) ?? image

        return blendImages(original: image, filtered: glitched, intensity: intensity)
    }

    // MARK: - Fisheye

    private func applyFisheye(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent
        let center = CIVector(x: extent.midX, y: extent.midY)
        let scale = intensity * 0.6

        guard let filter = cachedFilter(named: "CIBumpDistortion") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(min(extent.width, extent.height) * 0.45, forKey: kCIInputRadiusKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        return filter.outputImage?.cropped(to: extent) ?? image
    }

    // MARK: - Threshold

    private func applyThreshold(to image: CIImage, level: Double) -> CIImage {
        let grayFilter = CIFilter(name: "CIColorControls")!
        grayFilter.setValue(image, forKey: kCIInputImageKey)
        grayFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let gray = grayFilter.outputImage else { return image }

        let contrastFilter = CIFilter(name: "CIColorControls")!
        contrastFilter.setValue(gray, forKey: kCIInputImageKey)
        contrastFilter.setValue(4.0 + level * 20.0, forKey: kCIInputContrastKey)
        contrastFilter.setValue(level * -0.3, forKey: kCIInputBrightnessKey)
        let thresholded = contrastFilter.outputImage ?? image

        return blendImages(original: image, filtered: thresholded, intensity: level)
    }

    // MARK: - Light Leak

    private func applyLightLeak(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent

        // Use fresh filter instances to avoid conflict with cached ones
        let gradient = CIFilter(name: "CIRadialGradient")!
        let blend = CIFilter(name: "CIScreenBlendMode")!

        gradient.setValue(CIVector(x: extent.width * 0.8, y: extent.height * 0.7), forKey: "inputCenter")
        gradient.setValue(extent.width * 0.2, forKey: "inputRadius0")
        gradient.setValue(extent.width * 0.6, forKey: "inputRadius1")
        gradient.setValue(CIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: intensity), forKey: "inputColor0")
        gradient.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")

        guard let gradientImage = gradient.outputImage?.cropped(to: extent) else { return image }

        blend.setValue(image, forKey: kCIInputImageKey)
        blend.setValue(gradientImage, forKey: kCIInputBackgroundImageKey)
        return blend.outputImage ?? image
    }

    // MARK: - Grain

    private func applySimpleGrain(to image: CIImage, intensity: Double, size: Double) -> CIImage {
        let extent = image.extent

        // Use fresh noise filter to avoid concurrent access issues
        let noise = CIFilter(name: "CIRandomGenerator")!
        guard let noiseImage = noise.outputImage?.cropped(to: extent) else { return image }

        let scale = Float(intensity * 0.3)
        let matrix = CIFilter(name: "CIColorMatrix")!
        matrix.setValue(noiseImage, forKey: kCIInputImageKey)
        matrix.setValue(CIVector(x: CGFloat(scale), y: 0, z: 0, w: 0), forKey: "inputRVector")
        matrix.setValue(CIVector(x: 0, y: CGFloat(scale), z: 0, w: 0), forKey: "inputGVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: CGFloat(scale), w: 0), forKey: "inputBVector")
        matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        matrix.setValue(CIVector(x: CGFloat(-scale / 2), y: CGFloat(-scale / 2), z: CGFloat(-scale / 2), w: 0), forKey: "inputBiasVector")

        guard let grayNoise = matrix.outputImage else { return image }

        let maxDim = max(extent.width, extent.height)
        let resolutionScale = maxDim / 2000.0
        let userScale = 0.5 + size
        let totalScale = max(resolutionScale * userScale, 0.1)
        let transform = CGAffineTransform(scaleX: totalScale, y: totalScale)
        let scaledNoise = grayNoise.transformed(by: transform).cropped(to: extent)

        let add = CIFilter(name: "CIAdditionCompositing")!
        add.setValue(scaledNoise, forKey: kCIInputImageKey)
        add.setValue(image, forKey: kCIInputBackgroundImageKey)
        return add.outputImage ?? image
    }

    // MARK: - Helpers

    private func applyColorControls(to image: CIImage, brightness: Double, contrast: Double, saturation: Double) -> CIImage {
        colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        return colorControlsFilter.outputImage ?? image
    }

    private func blendImages(original: CIImage, filtered: CIImage, intensity: Double) -> CIImage {
        dissolveFilter.setValue(original, forKey: kCIInputImageKey)
        dissolveFilter.setValue(filtered, forKey: kCIInputTargetImageKey)
        dissolveFilter.setValue(intensity, forKey: kCIInputTimeKey)
        return dissolveFilter.outputImage ?? filtered
    }

    // MARK: - Rendering

    func renderToUIImage(_ ciImage: CIImage) -> UIImage? {
        let extent = ciImage.extent
        guard !extent.isInfinite, extent.width > 0, extent.height > 0 else { return nil }
        return ciImage.toUIImage(context: context)
    }

    func renderToCGImage(_ ciImage: CIImage) -> CGImage? {
        let extent = ciImage.extent
        guard !extent.isInfinite, extent.width > 0, extent.height > 0 else { return nil }
        return context.createCGImage(ciImage, from: extent)
    }

    func generateThumbnail(from image: CIImage, preset: FilterPreset, size: CGSize) -> UIImage? {
        let scale = min(size.width / image.extent.width, size.height / image.extent.height)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let filtered = applyPreset(preset, to: scaled, intensity: 1.0)
        return renderToUIImage(filtered)
    }

    // MARK: - Overlays

    /// Composites a texture overlay PNG over the image with adjustable opacity.
    /// Uses CISourceOverCompositing for GPU-accelerated compositing.
    func applyOverlay(_ overlayId: String, to image: CIImage, intensity: Double) -> CIImage {
        guard let asset = OverlayAsset.allOverlays.first(where: { $0.id == overlayId }),
              let overlayUIImage = UIImage(named: asset.fileName),
              var overlayCIImage = CIImage(image: overlayUIImage) else { return image }

        let extent = image.extent

        // Scale overlay to match image size
        let scaleX = extent.width / overlayCIImage.extent.width
        let scaleY = extent.height / overlayCIImage.extent.height
        overlayCIImage = overlayCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Adjust opacity via alpha channel
        if intensity < 1.0 {
            let alphaFilter = CIFilter(name: "CIColorMatrix")!
            alphaFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
            alphaFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
            alphaFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
            alphaFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
            alphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
            overlayCIImage = alphaFilter.outputImage ?? overlayCIImage
        }

        // Composite overlay over source image
        let compositeFilter = CIFilter(name: "CISourceOverCompositing")!
        compositeFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
        compositeFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        return compositeFilter.outputImage?.cropped(to: extent) ?? image
    }
}
