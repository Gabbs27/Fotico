# Professional Editor Effects — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 6 new professional effects (Dust, Halation, Chromatic Aberration, Film Burn, Soft Diffusion, Letterbox) to the photo editor.

**Architecture:** Each effect follows the existing pattern: add enum case → add EditState property → implement CIFilter pipeline in ImageFilterService → wire into ViewModel switch statements. The grid UI auto-populates via `EffectType.allCases`.

**Tech Stack:** Swift, CoreImage (CIFilter), SwiftUI

---

### Task 1: Add Effect Types to EffectType Enum

**Files:**
- Modify: `Fotico/Models/EffectType.swift`

**Step 1: Add 6 new cases to `EffectType`**

In `Fotico/Models/EffectType.swift`, add the new cases after `.threshold`:

```swift
enum EffectType: String, CaseIterable, Sendable, Identifiable {
    case grain
    case lightLeak
    case bloom
    case vignette
    case solarize
    case glitch
    case fisheye
    case threshold
    // New pro effects
    case dust
    case halation
    case chromaticAberration
    case filmBurn
    case softDiffusion
    case letterbox
```

**Step 2: Add display names**

Add to the `displayName` switch:

```swift
case .dust: return "Polvo"
case .halation: return "Halación"
case .chromaticAberration: return "Aberración"
case .filmBurn: return "Quemadura"
case .softDiffusion: return "Difusión"
case .letterbox: return "Cinemascope"
```

**Step 3: Add icons**

Add to the `icon` switch:

```swift
case .dust: return "aqi.medium"
case .halation: return "sun.haze.fill"
case .chromaticAberration: return "rainbow"
case .filmBurn: return "flame.fill"
case .softDiffusion: return "drop.fill"
case .letterbox: return "rectangle.expand.vertical"
```

**Step 4: Build to verify compilation**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: Build will FAIL because the new cases are not handled in switch statements (EditState, ViewModel, ImageFilterService). This is expected — we fix them in the next tasks.

---

### Task 2: Add EditState Properties

**Files:**
- Modify: `Fotico/Models/EditState.swift:28-30`

**Step 1: Add 6 new properties after line 30 (`thresholdLevel`)**

```swift
    // Pro effects
    var dustIntensity: Double = 0.0             // 0.0...1.0
    var halationIntensity: Double = 0.0         // 0.0...1.0
    var chromaticAberrationIntensity: Double = 0.0 // 0.0...1.0
    var filmBurnIntensity: Double = 0.0         // 0.0...1.0
    var softDiffusionIntensity: Double = 0.0    // 0.0...1.0
    var letterboxIntensity: Double = 0.0        // 0.0...1.0
```

Note: `EditState` conforms to `Codable` — since all new properties have default values (0.0), existing saved states will decode correctly with the new fields defaulting to 0.

---

### Task 3: Wire ViewModel Switch Statements

**Files:**
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift:153-178`

**Step 1: Add cases to `updateEffect(_:intensity:)` (line ~162)**

Before the closing `}` of the switch, add:

```swift
case .dust: editState.dustIntensity = intensity
case .halation: editState.halationIntensity = intensity
case .chromaticAberration: editState.chromaticAberrationIntensity = intensity
case .filmBurn: editState.filmBurnIntensity = intensity
case .softDiffusion: editState.softDiffusionIntensity = intensity
case .letterbox: editState.letterboxIntensity = intensity
```

**Step 2: Add cases to `effectIntensity(for:)` (line ~177)**

Before the closing `}` of the switch, add:

```swift
case .dust: return editState.dustIntensity
case .halation: return editState.halationIntensity
case .chromaticAberration: return editState.chromaticAberrationIntensity
case .filmBurn: return editState.filmBurnIntensity
case .softDiffusion: return editState.softDiffusionIntensity
case .letterbox: return editState.letterboxIntensity
```

**Step 3: Build to verify compilation**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED. At this point all switch statements are exhaustive. The effects don't do anything yet (intensity 0 = skipped), but the app compiles and the new effect buttons appear in the grid.

**Step 4: Commit**

```bash
git add Fotico/Models/EffectType.swift Fotico/Models/EditState.swift Fotico/ViewModels/PhotoEditorViewModel.swift
git commit -m "feat: add 6 pro effect types (dust, halation, chromatic aberration, film burn, soft diffusion, letterbox)

Wire enum cases, EditState properties, and ViewModel switch
statements. Effects appear in grid but are no-ops until filter
implementations are added."
```

---

### Task 4: Implement Dust Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applyDust` method**

Add after the `applySimpleGrain` method (~line 440):

```swift
// MARK: - Dust

private func applyDust(to image: CIImage, intensity: Double) -> CIImage {
    // Use first dust overlay asset
    guard let dustImage = UIImage(named: "dust_01"),
          var dustCI = CIImage(image: dustImage) else { return image }

    let extent = image.extent

    // Scale dust to fill image
    let scaleX = extent.width / dustCI.extent.width
    let scaleY = extent.height / dustCI.extent.height
    dustCI = dustCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

    // Adjust opacity via alpha
    let alphaFilter = CIFilter(name: "CIColorMatrix")!
    alphaFilter.setValue(dustCI, forKey: kCIInputImageKey)
    alphaFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
    alphaFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
    alphaFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
    alphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
    dustCI = alphaFilter.outputImage ?? dustCI

    // Screen blend for bright dust particles
    let screenBlend = CIFilter(name: "CIScreenBlendMode")!
    screenBlend.setValue(dustCI, forKey: kCIInputImageKey)
    screenBlend.setValue(image, forKey: kCIInputBackgroundImageKey)
    return screenBlend.outputImage?.cropped(to: extent) ?? image
}
```

**Step 2: Wire into `applyEffects` pipeline**

In `applyEffects(_:to:)`, add after the grain block (before the "Ensure finite extent" comment):

```swift
if state.dustIntensity > 0 {
    result = applyDust(to: result, intensity: state.dustIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement dust effect

Screen-blends dust_01 overlay with intensity-controlled alpha.
Uses existing dust PNG asset from overlay system."
```

---

### Task 5: Implement Halation Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applyHalation` method**

```swift
// MARK: - Halation

private func applyHalation(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent

    // 1. Extract highlights by boosting exposure and clamping
    let highlightExposure = CIFilter(name: "CIExposureAdjust")!
    highlightExposure.setValue(image, forKey: kCIInputImageKey)
    highlightExposure.setValue(1.5, forKey: kCIInputEVKey)
    guard let brightened = highlightExposure.outputImage else { return image }

    // Clamp to highlight range using color clamp
    let clamp = CIFilter(name: "CIColorClamp")!
    clamp.setValue(brightened, forKey: kCIInputImageKey)
    clamp.setValue(CIVector(x: 0.6, y: 0.6, z: 0.6, w: 0), forKey: "inputMinComponents")
    clamp.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")
    guard let highlights = clamp.outputImage else { return image }

    // 2. Blur the highlights heavily
    let blur = CIFilter(name: "CIGaussianBlur")!
    blur.setValue(highlights, forKey: kCIInputImageKey)
    blur.setValue(30.0 * intensity, forKey: kCIInputRadiusKey)
    guard let blurred = blur.outputImage?.cropped(to: extent) else { return image }

    // 3. Tint warm red/orange
    let tint = CIFilter(name: "CIColorMatrix")!
    tint.setValue(blurred, forKey: kCIInputImageKey)
    tint.setValue(CIVector(x: 1.0, y: 0, z: 0, w: 0), forKey: "inputRVector")
    tint.setValue(CIVector(x: 0, y: 0.4, z: 0, w: 0), forKey: "inputGVector")
    tint.setValue(CIVector(x: 0, y: 0, z: 0.15, w: 0), forKey: "inputBVector")
    tint.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    guard let tinted = tint.outputImage else { return image }

    // 4. Screen blend back onto original
    let blend = CIFilter(name: "CIScreenBlendMode")!
    blend.setValue(tinted, forKey: kCIInputImageKey)
    blend.setValue(image, forKey: kCIInputBackgroundImageKey)
    guard let blended = blend.outputImage?.cropped(to: extent) else { return image }

    // 5. Mix with original based on intensity
    return blendImages(original: image, filtered: blended, intensity: intensity)
}
```

**Step 2: Wire into `applyEffects` pipeline**

Add in `applyEffects`, after grain and before dust:

```swift
// Pro effects (order: chromatic aberration → halation → soft diffusion → film burn → dust → letterbox)
if state.halationIntensity > 0 {
    result = applyHalation(to: result, intensity: state.halationIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement halation effect

Extracts highlights → gaussian blur → tint red/orange → screen blend.
Mimics analog film halation glow around bright areas."
```

---

### Task 6: Implement Chromatic Aberration Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applyChromaticAberration` method**

```swift
// MARK: - Chromatic Aberration

private func applyChromaticAberration(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent
    let offsetAmount = intensity * 8.0  // Max 8px offset at full intensity

    // Separate channels
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
        .transformed(by: CGAffineTransform(translationX: -offsetAmount, y: 0))
        .cropped(to: extent) ?? image

    // Recompose
    let addRG = CIFilter(name: "CIAdditionCompositing")!
    addRG.setValue(redChannel, forKey: kCIInputImageKey)
    addRG.setValue(greenChannel, forKey: kCIInputBackgroundImageKey)
    let rg = addRG.outputImage ?? image

    let addRGB = CIFilter(name: "CIAdditionCompositing")!
    addRGB.setValue(blueChannel, forKey: kCIInputImageKey)
    addRGB.setValue(rg, forKey: kCIInputBackgroundImageKey)
    let aberrated = addRGB.outputImage?.cropped(to: extent) ?? image

    // Create radial mask: sharp center, effect on edges
    let center = CIVector(x: extent.midX, y: extent.midY)
    let maskGradient = CIFilter(name: "CIRadialGradient")!
    maskGradient.setValue(center, forKey: "inputCenter")
    maskGradient.setValue(min(extent.width, extent.height) * 0.25, forKey: "inputRadius0")
    maskGradient.setValue(min(extent.width, extent.height) * 0.7, forKey: "inputRadius1")
    maskGradient.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 1), forKey: "inputColor0")  // Center: original
    maskGradient.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: 1), forKey: "inputColor1")  // Edges: aberrated
    guard let mask = maskGradient.outputImage?.cropped(to: extent) else { return aberrated }

    // Blend using mask: original in center, aberrated on edges
    let blendWithMask = CIFilter(name: "CIBlendWithMask")!
    blendWithMask.setValue(aberrated, forKey: kCIInputImageKey)
    blendWithMask.setValue(image, forKey: kCIInputBackgroundImageKey)
    blendWithMask.setValue(mask, forKey: kCIInputMaskImageKey)
    return blendWithMask.outputImage?.cropped(to: extent) ?? aberrated
}
```

**Step 2: Wire into `applyEffects` pipeline**

Add before halation in the pro effects section:

```swift
if state.chromaticAberrationIntensity > 0 {
    result = applyChromaticAberration(to: result, intensity: state.chromaticAberrationIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement chromatic aberration

RGB channel separation with radial edge mask — center stays sharp,
edges show color fringing. Similar to lens distortion in vintage optics."
```

---

### Task 7: Implement Film Burn Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applyFilmBurn` method**

```swift
// MARK: - Film Burn

private func applyFilmBurn(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent

    // Create warm gradient from corner
    let gradient = CIFilter(name: "CILinearGradient")!
    gradient.setValue(CIVector(x: extent.width * 0.9, y: extent.height * 0.85), forKey: "inputPoint0")
    gradient.setValue(CIVector(x: extent.width * 0.3, y: extent.height * 0.2), forKey: "inputPoint1")
    gradient.setValue(CIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: CGFloat(intensity) * 0.8), forKey: "inputColor0")
    gradient.setValue(CIColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0), forKey: "inputColor1")
    guard let burn = gradient.outputImage?.cropped(to: extent) else { return image }

    // Screen blend
    let blend = CIFilter(name: "CIScreenBlendMode")!
    blend.setValue(burn, forKey: kCIInputImageKey)
    blend.setValue(image, forKey: kCIInputBackgroundImageKey)
    return blend.outputImage?.cropped(to: extent) ?? image
}
```

**Step 2: Wire into `applyEffects` pipeline**

Add after soft diffusion, before dust:

```swift
if state.filmBurnIntensity > 0 {
    result = applyFilmBurn(to: result, intensity: state.filmBurnIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement film burn effect

Linear gradient from top-right corner with warm orange/red,
screen-blended. Simulates light burn on partially exposed film."
```

---

### Task 8: Implement Soft Diffusion Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applySoftDiffusion` method**

```swift
// MARK: - Soft Diffusion

private func applySoftDiffusion(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent

    // 1. Blur the image
    let blur = CIFilter(name: "CIGaussianBlur")!
    blur.setValue(image, forKey: kCIInputImageKey)
    blur.setValue(20.0 * intensity, forKey: kCIInputRadiusKey)
    guard let blurred = blur.outputImage?.cropped(to: extent) else { return image }

    // 2. Brighten the blurred version slightly to push highlights
    let brighten = CIFilter(name: "CIExposureAdjust")!
    brighten.setValue(blurred, forKey: kCIInputImageKey)
    brighten.setValue(0.3 * intensity, forKey: kCIInputEVKey)
    let brightBlur = brighten.outputImage ?? blurred

    // 3. Screen blend: adds the bright blur onto original, creating highlight glow
    let screen = CIFilter(name: "CIScreenBlendMode")!
    screen.setValue(brightBlur, forKey: kCIInputImageKey)
    screen.setValue(image, forKey: kCIInputBackgroundImageKey)
    guard let screened = screen.outputImage?.cropped(to: extent) else { return image }

    // 4. Mix with original at reduced strength (screen is strong)
    return blendImages(original: image, filtered: screened, intensity: intensity * 0.6)
}
```

**Step 2: Wire into `applyEffects` pipeline**

Add after halation, before film burn:

```swift
if state.softDiffusionIntensity > 0 {
    result = applySoftDiffusion(to: result, intensity: state.softDiffusionIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement soft diffusion (Pro-Mist filter)

Gaussian blur → slight exposure boost → screen blend at reduced
opacity. Creates dreamy highlight glow while preserving sharpness."
```

---

### Task 9: Implement Letterbox Effect

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add `applyLetterbox` method**

```swift
// MARK: - Letterbox

private func applyLetterbox(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent

    // Calculate bar height: at full intensity, reach 2.39:1 cinematic ratio
    // Bar percentage of total height: (1 - currentRatio/targetRatio) / 2
    let currentRatio = extent.width / extent.height
    let targetRatio: CGFloat = 2.39
    guard currentRatio < targetRatio else { return image }  // Already wider than cinematic

    let fullBarFraction = (1.0 - currentRatio / targetRatio) / 2.0
    let barHeight = extent.height * fullBarFraction * CGFloat(intensity)
    guard barHeight > 1 else { return image }

    // Create black bars
    let black = CIFilter(name: "CIConstantColorGenerator")!
    black.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 1), forKey: kCIInputColorKey)
    guard let blackImage = black.outputImage else { return image }

    // Bottom bar
    let bottomBar = blackImage.cropped(to: CGRect(x: extent.origin.x, y: extent.origin.y,
                                                   width: extent.width, height: barHeight))
    let compBottom = CIFilter(name: "CISourceOverCompositing")!
    compBottom.setValue(bottomBar, forKey: kCIInputImageKey)
    compBottom.setValue(image, forKey: kCIInputBackgroundImageKey)
    guard let withBottom = compBottom.outputImage else { return image }

    // Top bar
    let topBarY = extent.origin.y + extent.height - barHeight
    let topBar = blackImage.cropped(to: CGRect(x: extent.origin.x, y: topBarY,
                                                width: extent.width, height: barHeight))
    let compTop = CIFilter(name: "CISourceOverCompositing")!
    compTop.setValue(topBar, forKey: kCIInputImageKey)
    compTop.setValue(withBottom, forKey: kCIInputBackgroundImageKey)
    return compTop.outputImage?.cropped(to: extent) ?? image
}
```

**Step 2: Wire into `applyEffects` pipeline**

Add as the LAST pro effect, after dust:

```swift
if state.letterboxIntensity > 0 {
    result = applyLetterbox(to: result, intensity: state.letterboxIntensity)
}
```

**Step 3: Build and verify**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat(effects): implement letterbox (cinemascope) effect

Black bars at top and bottom, scaling from none to full 2.39:1
cinematic ratio based on intensity slider."
```

---

### Task 10: Final Integration Build & Verify

**Step 1: Full clean build**

Run: `xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Verify the complete effect pipeline order in `applyEffects`**

The method should now have this order:
1. Vignette (existing)
2. Bloom (existing)
3. Solarize (existing)
4. Light Leak (existing)
5. Glitch (existing)
6. Fisheye (existing)
7. Threshold (existing)
8. Grain (existing)
9. Chromatic Aberration (new)
10. Halation (new)
11. Soft Diffusion (new)
12. Film Burn (new)
13. Dust (new)
14. Letterbox (new — always last)
15. Ensure finite extent

**Step 3: Verify EffectType has exactly 14 cases**

Check that `EffectType.allCases.count` covers all 14 effects.

**Step 4: Final commit if any tweaks needed**

```bash
git add -A
git commit -m "feat: complete 6 pro effects integration

All 14 effects now available in editor: grain, light leak, bloom,
vignette, solarize, glitch, fisheye, threshold, dust, halation,
chromatic aberration, film burn, soft diffusion, letterbox."
```
