import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

/// Thread-safe filter service — all methods can be called from any thread.
/// Uses Metal-backed CIContext for GPU-accelerated rendering.
class ImageFilterService: @unchecked Sendable {
    private let context: CIContext

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpaceCreateDeviceRGB()
            ])
        } else {
            self.context = CIContext(options: [.useSoftwareRenderer: false])
        }
    }

    // MARK: - Full Pipeline

    func applyEdits(to sourceImage: CIImage, state: EditState, presets: [FilterPreset]) -> CIImage {
        var image = sourceImage

        // 1. Apply rotation
        if state.rotation != 0 {
            let radians = state.rotation * .pi / 180.0
            let transform = CGAffineTransform(rotationAngle: radians)
            image = image.transformed(by: transform)
            // Re-center after rotation
            let offset = image.extent.origin
            image = image.transformed(by: CGAffineTransform(translationX: -offset.x, y: -offset.y))
        }

        // 2. Apply preset
        if let presetId = state.selectedPresetId,
           let preset = presets.first(where: { $0.id == presetId }) {
            image = applyPreset(preset, to: image, intensity: state.presetIntensity)
        }

        // 3. Apply basic adjustments
        image = applyAdjustments(state, to: image)

        // 4. Apply effects
        image = applyEffects(state, to: image)

        return image
    }

    // MARK: - Presets

    func applyPreset(_ preset: FilterPreset, to image: CIImage, intensity: Double) -> CIImage {
        var filtered: CIImage

        if let ciFilterName = preset.ciFilterName {
            filtered = applyStandardPreset(ciFilterName, to: image)
        } else {
            filtered = applyCustomPreset(preset, to: image)
        }

        // Apply additional preset parameters
        for param in preset.parameters {
            filtered = applyParameter(param, to: filtered)
        }

        // Blend with original based on intensity
        if intensity < 1.0 {
            filtered = blendImages(original: image, filtered: filtered, intensity: intensity)
        }

        return filtered
    }

    private func applyStandardPreset(_ filterName: String, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: filterName) else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    private func applyCustomPreset(_ preset: FilterPreset, to image: CIImage) -> CIImage {
        switch preset.id {
        case "east_cine":
            return applyCinematicGrade(to: image, preset: preset)
        case "east_retro":
            return applyRetroLook(to: image, preset: preset)
        default:
            // Generic custom presets — just apply their parameters
            return image
        }
    }

    private func applyCinematicGrade(to image: CIImage, preset: FilterPreset) -> CIImage {
        var result = image

        // Increase contrast
        let contrastValue = preset.parameters.first(where: { $0.key == "contrast" })?.value ?? 1.2
        result = applyColorControls(to: result, brightness: 0, contrast: contrastValue, saturation: 1.0)

        // Teal shadows + orange highlights via temperature shift
        let tempFilter = CIFilter(name: "CITemperatureAndTint")!
        tempFilter.setValue(result, forKey: kCIInputImageKey)
        tempFilter.setValue(CIVector(x: 5500, y: 0), forKey: "inputNeutral")
        tempFilter.setValue(CIVector(x: 7000, y: -20), forKey: "inputTargetNeutral")
        result = tempFilter.outputImage ?? result

        return result
    }

    private func applyRetroLook(to image: CIImage, preset: FilterPreset) -> CIImage {
        var result = image

        // Desaturate
        let satValue = preset.parameters.first(where: { $0.key == "saturation" })?.value ?? 0.6
        result = applyColorControls(to: result, brightness: 0.03, contrast: 1.0, saturation: satValue)

        // Warm temperature
        let tempFilter = CIFilter(name: "CITemperatureAndTint")!
        tempFilter.setValue(result, forKey: kCIInputImageKey)
        tempFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        tempFilter.setValue(CIVector(x: 7500, y: 0), forKey: "inputTargetNeutral")
        result = tempFilter.outputImage ?? result

        // Add slight vignette
        let vignetteFilter = CIFilter(name: "CIVignette")!
        vignetteFilter.setValue(result, forKey: kCIInputImageKey)
        vignetteFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        vignetteFilter.setValue(1.5, forKey: kCIInputRadiusKey)
        result = vignetteFilter.outputImage ?? result

        return result
    }

    private func applyParameter(_ param: FilterParameter, to image: CIImage) -> CIImage {
        switch param.key {
        case "temperature":
            let filter = CIFilter(name: "CITemperatureAndTint")!
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: param.value, y: 0), forKey: "inputTargetNeutral")
            return filter.outputImage ?? image
        case "contrast":
            return applyColorControls(to: image, brightness: 0, contrast: param.value, saturation: 1.0)
        case "brightness":
            return applyColorControls(to: image, brightness: param.value, contrast: 1.0, saturation: 1.0)
        case "saturation":
            return applyColorControls(to: image, brightness: 0, contrast: 1.0, saturation: param.value)
        case "vibrance":
            let filter = CIFilter(name: "CIVibrance")!
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(param.value, forKey: "inputAmount")
            return filter.outputImage ?? image
        case "vignette":
            let filter = CIFilter(name: "CIVignette")!
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(param.value, forKey: kCIInputIntensityKey)
            filter.setValue(1.5, forKey: kCIInputRadiusKey)
            return filter.outputImage ?? image
        default:
            return image
        }
    }

    // MARK: - Adjustments

    func applyAdjustments(_ state: EditState, to image: CIImage) -> CIImage {
        var result = image

        // Color controls (brightness, contrast, saturation)
        if state.brightness != 0 || state.contrast != 1.0 || state.saturation != 1.0 {
            result = applyColorControls(
                to: result,
                brightness: state.brightness,
                contrast: state.contrast,
                saturation: state.saturation
            )
        }

        // Exposure
        if state.exposure != 0 {
            let filter = CIFilter(name: "CIExposureAdjust")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(state.exposure, forKey: kCIInputEVKey)
            result = filter.outputImage ?? result
        }

        // Temperature & Tint
        if state.temperature != 6500 || state.tint != 0 {
            let filter = CIFilter(name: "CITemperatureAndTint")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: state.temperature, y: state.tint), forKey: "inputTargetNeutral")
            result = filter.outputImage ?? result
        }

        // Vibrance
        if state.vibrance != 0 {
            let filter = CIFilter(name: "CIVibrance")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(state.vibrance, forKey: "inputAmount")
            result = filter.outputImage ?? result
        }

        // Sharpness
        if state.sharpness > 0 {
            let filter = CIFilter(name: "CISharpenLuminance")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(state.sharpness, forKey: kCIInputSharpnessKey)
            result = filter.outputImage ?? result
        }

        return result
    }

    // MARK: - Effects

    func applyEffects(_ state: EditState, to image: CIImage) -> CIImage {
        var result = image

        // Vignette
        if state.vignetteIntensity > 0 {
            let filter = CIFilter(name: "CIVignette")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(state.vignetteIntensity, forKey: kCIInputIntensityKey)
            filter.setValue(state.vignetteRadius, forKey: kCIInputRadiusKey)
            result = filter.outputImage ?? result
        }

        // Bloom
        if state.bloomIntensity > 0 {
            let filter = CIFilter(name: "CIBloom")!
            filter.setValue(result, forKey: kCIInputImageKey)
            filter.setValue(state.bloomIntensity, forKey: kCIInputIntensityKey)
            filter.setValue(state.bloomRadius, forKey: kCIInputRadiusKey)
            result = filter.outputImage ?? result
        }

        // Solarize
        if state.solarizeThreshold > 0 {
            let colorControls = CIFilter(name: "CIColorControls")!
            colorControls.setValue(result, forKey: kCIInputImageKey)
            colorControls.setValue(1.0 + state.solarizeThreshold, forKey: kCIInputContrastKey)
            if let contrastImage = colorControls.outputImage {
                let invertFilter = CIFilter(name: "CIColorInvert")!
                invertFilter.setValue(contrastImage, forKey: kCIInputImageKey)
                if let inverted = invertFilter.outputImage {
                    result = blendImages(original: result, filtered: inverted, intensity: state.solarizeThreshold)
                }
            }
        }

        // Light Leak (simple CIFilter-based version for Phase 1)
        if state.lightLeakIntensity > 0 {
            result = applyLightLeak(to: result, intensity: state.lightLeakIntensity)
        }

        // Glitch (RGB channel offset)
        if state.glitchIntensity > 0 {
            result = applyGlitch(to: result, intensity: state.glitchIntensity)
        }

        // Fisheye (barrel distortion)
        if state.fisheyeIntensity > 0 {
            result = applyFisheye(to: result, intensity: state.fisheyeIntensity)
        }

        // Threshold (high-contrast binary)
        if state.thresholdLevel > 0 {
            result = applyThreshold(to: result, level: state.thresholdLevel)
        }

        // Grain (simple noise-based for Phase 1, Metal shader in Phase 2)
        if state.grainIntensity > 0 {
            result = applySimpleGrain(to: result, intensity: state.grainIntensity, size: state.grainSize)
        }

        return result
    }

    // MARK: - Glitch (RGB Channel Offset)

    private func applyGlitch(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent
        let offsetAmount = intensity * 20.0 // Max 20px offset

        // Separate RGB channels using color matrices
        // Red channel - shift right
        let redMatrix = CIFilter(name: "CIColorMatrix")!
        redMatrix.setValue(image, forKey: kCIInputImageKey)
        redMatrix.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let redChannel = redMatrix.outputImage?
            .transformed(by: CGAffineTransform(translationX: offsetAmount, y: 0))
            .cropped(to: extent) ?? image

        // Green channel - no shift
        let greenMatrix = CIFilter(name: "CIColorMatrix")!
        greenMatrix.setValue(image, forKey: kCIInputImageKey)
        greenMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        greenMatrix.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        greenMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        greenMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let greenChannel = greenMatrix.outputImage?.cropped(to: extent) ?? image

        // Blue channel - shift left
        let blueMatrix = CIFilter(name: "CIColorMatrix")!
        blueMatrix.setValue(image, forKey: kCIInputImageKey)
        blueMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blueMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blueMatrix.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        blueMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let blueChannel = blueMatrix.outputImage?
            .transformed(by: CGAffineTransform(translationX: -offsetAmount, y: offsetAmount * 0.3))
            .cropped(to: extent) ?? image

        // Recombine: additive compositing of the 3 channels
        let addRG = CIFilter(name: "CIAdditionCompositing")!
        addRG.setValue(redChannel, forKey: kCIInputImageKey)
        addRG.setValue(greenChannel, forKey: kCIInputBackgroundImageKey)
        let rg = addRG.outputImage ?? image

        let addRGB = CIFilter(name: "CIAdditionCompositing")!
        addRGB.setValue(blueChannel, forKey: kCIInputImageKey)
        addRGB.setValue(rg, forKey: kCIInputBackgroundImageKey)
        let glitched = addRGB.outputImage?.cropped(to: extent) ?? image

        // Blend with original based on intensity
        return blendImages(original: image, filtered: glitched, intensity: intensity)
    }

    // MARK: - Fisheye (Barrel Distortion)

    private func applyFisheye(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent
        let center = CIVector(x: extent.midX, y: extent.midY)
        let scale = intensity * 0.6 // Scale factor for distortion

        let filter = CIFilter(name: "CIBumpDistortion")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(min(extent.width, extent.height) * 0.45, forKey: kCIInputRadiusKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        return filter.outputImage?.cropped(to: extent) ?? image
    }

    // MARK: - Threshold (High-Contrast Binary)

    private func applyThreshold(to image: CIImage, level: Double) -> CIImage {
        // Convert to grayscale
        let grayFilter = CIFilter(name: "CIColorControls")!
        grayFilter.setValue(image, forKey: kCIInputImageKey)
        grayFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let gray = grayFilter.outputImage else { return image }

        // Apply extreme contrast to create threshold effect
        let contrastFilter = CIFilter(name: "CIColorControls")!
        contrastFilter.setValue(gray, forKey: kCIInputImageKey)
        contrastFilter.setValue(4.0 + level * 20.0, forKey: kCIInputContrastKey)
        contrastFilter.setValue(level * -0.3, forKey: kCIInputBrightnessKey)
        let thresholded = contrastFilter.outputImage ?? image

        // Blend with original
        return blendImages(original: image, filtered: thresholded, intensity: level)
    }

    // MARK: - Light Leak (CIFilter-based)

    private func applyLightLeak(to image: CIImage, intensity: Double) -> CIImage {
        let extent = image.extent

        let gradient = CIFilter(name: "CIRadialGradient")!
        gradient.setValue(CIVector(x: extent.width * 0.8, y: extent.height * 0.7), forKey: "inputCenter")
        gradient.setValue(extent.width * 0.2, forKey: "inputRadius0")
        gradient.setValue(extent.width * 0.6, forKey: "inputRadius1")
        gradient.setValue(CIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: intensity), forKey: "inputColor0")
        gradient.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")

        guard let gradientImage = gradient.outputImage?.cropped(to: extent) else { return image }

        let blend = CIFilter(name: "CIScreenBlendMode")!
        blend.setValue(image, forKey: kCIInputImageKey)
        blend.setValue(gradientImage, forKey: kCIInputBackgroundImageKey)
        return blend.outputImage ?? image
    }

    // MARK: - Simple Grain (CIFilter-based fallback)

    private func applySimpleGrain(to image: CIImage, intensity: Double, size: Double) -> CIImage {
        let extent = image.extent

        let noiseFilter = CIFilter(name: "CIRandomGenerator")!
        guard let noise = noiseFilter.outputImage?.cropped(to: extent) else { return image }

        // Convert to grayscale noise
        let grayFilter = CIFilter(name: "CIColorMatrix")!
        grayFilter.setValue(noise, forKey: kCIInputImageKey)
        let scale = Float(intensity * 0.3)
        grayFilter.setValue(CIVector(x: CGFloat(scale), y: 0, z: 0, w: 0), forKey: "inputRVector")
        grayFilter.setValue(CIVector(x: 0, y: CGFloat(scale), z: 0, w: 0), forKey: "inputGVector")
        grayFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(scale), w: 0), forKey: "inputBVector")
        grayFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        grayFilter.setValue(CIVector(x: CGFloat(-scale / 2), y: CGFloat(-scale / 2), z: CGFloat(-scale / 2), w: 0), forKey: "inputBiasVector")

        guard let grayNoise = grayFilter.outputImage else { return image }

        // Scale noise: base scale from resolution + user grain size adjustment
        let maxDim = max(extent.width, extent.height)
        let resolutionScale = maxDim / 2000.0  // Reference resolution
        let userScale = 0.5 + size
        let totalScale = max(resolutionScale * userScale, 0.1)
        let transform = CGAffineTransform(scaleX: totalScale, y: totalScale)
        let scaledNoise = grayNoise.transformed(by: transform).cropped(to: extent)

        // Blend noise with image using additive blend
        let blend = CIFilter(name: "CIAdditionCompositing")!
        blend.setValue(scaledNoise, forKey: kCIInputImageKey)
        blend.setValue(image, forKey: kCIInputBackgroundImageKey)
        return blend.outputImage ?? image
    }

    // MARK: - Helpers

    private func applyColorControls(to image: CIImage, brightness: Double, contrast: Double, saturation: Double) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        return filter.outputImage ?? image
    }

    private func blendImages(original: CIImage, filtered: CIImage, intensity: Double) -> CIImage {
        let blend = CIFilter(name: "CIDissolveTransition")!
        blend.setValue(original, forKey: kCIInputImageKey)
        blend.setValue(filtered, forKey: kCIInputTargetImageKey)
        blend.setValue(intensity, forKey: kCIInputTimeKey)
        return blend.outputImage ?? filtered
    }

    // MARK: - Rendering

    func renderToUIImage(_ ciImage: CIImage) -> UIImage? {
        return ciImage.toUIImage(context: context)
    }

    func generateThumbnail(from image: CIImage, preset: FilterPreset, size: CGSize) -> UIImage? {
        // Scale down for thumbnail
        let scale = min(size.width / image.extent.width, size.height / image.extent.height)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let filtered = applyPreset(preset, to: scaled, intensity: 1.0)
        return renderToUIImage(filtered)
    }
}
