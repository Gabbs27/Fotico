# Lumé Improvements Pack Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 12 improvements to the Lumé photo editor: Highlights & Shadows, Clarity, Film Blur, Low-Res effect, Before/After preview, Favorite Presets, Aspect Ratio presets, Edges/Borders, Color Tone (split toning), HSL panel, Text Tool, and Labbet Link sharing.

**Architecture:** All new adjustments/effects follow existing patterns: add properties to `EditState` (Codable, auto-handled by `isDefault`/`reset()`), add CIFilter chains in `ImageFilterService`, add UI controls in corresponding panel views. New tools get new `EditorTool` cases. EditState equality comparison handles all new properties automatically.

**Tech Stack:** SwiftUI, CoreImage (CIFilter chains), Metal compute shaders (for HSL), UIKit (CGContext for text rendering)

---

### Task 1: Add Highlights, Shadows & Clarity to EditState

**Files:**
- Modify: `Fotico/Models/EditState.swift`

**Step 1: Add 3 new properties after the `tint` property:**

```swift
// After line "var tint: Double = 0.0  // -150...150"
// Add:

// Highlights & Shadows
var highlights: Double = 0.0        // -1.0...1.0 (0 = neutral)
var shadows: Double = 0.0           // -1.0...1.0 (0 = neutral)

// Clarity (local contrast)
var clarity: Double = 0.0           // 0.0...2.0 (0 = off)
```

No changes needed to `isDefault` or `reset()` — they use `self == EditState()` pattern.

**Step 2: Commit**
```bash
git add Fotico/Models/EditState.swift
git commit -m "feat: add highlights, shadows, clarity properties to EditState"
```

---

### Task 2: Implement Highlights, Shadows & Clarity in ImageFilterService

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add cached filter instances at the top (with other filter declarations around line 32):**

```swift
private let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")!
private let clarityFilter = CIFilter(name: "CIUnsharpMask")!
```

**Step 2: Add highlight/shadow/clarity processing in `applyAdjustments` method, after the sharpness block (after line 247):**

```swift
// Highlights & Shadows
if state.highlights != 0 || state.shadows != 0 {
    highlightShadowFilter.setValue(result, forKey: kCIInputImageKey)
    highlightShadowFilter.setValue(state.highlights, forKey: "inputHighlightAmount")
    // CIHighlightShadowAdjust uses negative values to lighten shadows
    highlightShadowFilter.setValue(state.shadows, forKey: "inputShadowAmount")
    result = highlightShadowFilter.outputImage ?? result
}

// Clarity (local contrast via unsharp mask with large radius)
if state.clarity > 0 {
    let extent = result.extent
    let maxDim = max(extent.width, extent.height)
    clarityFilter.setValue(result, forKey: kCIInputImageKey)
    // Scale radius to image resolution for consistent look
    clarityFilter.setValue((maxDim / 1200.0) * 15.0, forKey: kCIInputRadiusKey)
    clarityFilter.setValue(state.clarity * 0.5, forKey: kCIInputIntensityKey)
    result = clarityFilter.outputImage ?? result
}
```

**Step 3: Commit**
```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat: implement highlights, shadows, clarity CIFilter processing"
```

---

### Task 3: Add Highlights, Shadows & Clarity sliders to AdjustmentPanelView

**Files:**
- Modify: `Fotico/Views/Editor/AdjustmentPanelView.swift`

**Step 1: Add 3 new sliders after the "Nitidez" slider (after the sharpness adjustmentSlider block, inside the VStack):**

```swift
adjustmentSlider(
    label: "Luces",
    icon: "sun.max.trianglebadge.exclamationmark",
    value: $editState.highlights,
    range: -1.0...1.0,
    defaultValue: 0
)
adjustmentSlider(
    label: "Sombras",
    icon: "moon.fill",
    value: $editState.shadows,
    range: -1.0...1.0,
    defaultValue: 0
)
adjustmentSlider(
    label: "Claridad",
    icon: "diamond",
    value: $editState.clarity,
    range: 0.0...2.0,
    defaultValue: 0
)
```

**Step 2: Add formatting cases for the new labels in `formattedValue`. Add before the `default:` case:**

```swift
case "Luces", "Sombras":
    let normalized = Int(value * 100)
    return normalized >= 0 ? "+\(normalized)" : "\(normalized)"
case "Claridad":
    let normalized = Int(value * 100)
    return "+\(normalized)"
```

**Step 3: Commit**
```bash
git add Fotico/Views/Editor/AdjustmentPanelView.swift
git commit -m "feat: add highlights, shadows, clarity sliders to adjustments panel"
```

---

### Task 4: Add Film Blur & Low-Res to EffectType and EditState

**Files:**
- Modify: `Fotico/Models/EffectType.swift`
- Modify: `Fotico/Models/EditState.swift`

**Step 1: Add `filmBlur` and `lowRes` cases to EffectType enum (after `motionBlur`):**

```swift
case filmBlur
case lowRes
```

**Step 2: Add displayName cases:**

```swift
case .filmBlur: return "Film Blur"
case .lowRes: return "Low-Res"
```

**Step 3: Add icon cases:**

```swift
case .filmBlur: return "aqi.medium"
case .lowRes: return "square.resize.down"
```

**Step 4: Add category cases:**

```swift
// Update the .blur case to include filmBlur:
case .motionBlur, .filmBlur: return .blur
// Update the .stylize case to include lowRes:
case .solarize, .glitch, .threshold, .letterbox, .lowRes: return .stylize
```

**Step 5: Add properties to EditState (in the Effects section):**

```swift
// Film Blur
var filmBlurIntensity: Double = 0.0     // 0.0...1.0

// Low-Res
var lowResIntensity: Double = 0.0       // 0.0...1.0
```

**Step 6: Commit**
```bash
git add Fotico/Models/EffectType.swift Fotico/Models/EditState.swift
git commit -m "feat: add filmBlur and lowRes effect types"
```

---

### Task 5: Add Film Blur & Low-Res to ViewModel switches

**Files:**
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`

**Step 1: Add cases to `updateEffect` method (around line 178):**

```swift
case .filmBlur: editState.filmBlurIntensity = intensity
case .lowRes: editState.lowResIntensity = intensity
```

**Step 2: Add cases to `effectIntensity` method (around line 199):**

```swift
case .filmBlur: return editState.filmBlurIntensity
case .lowRes: return editState.lowResIntensity
```

**Step 3: Commit**
```bash
git add Fotico/ViewModels/PhotoEditorViewModel.swift
git commit -m "feat: wire filmBlur and lowRes into ViewModel effect switches"
```

---

### Task 6: Implement Film Blur & Low-Res in ImageFilterService

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add Film Blur filter (add cached filter):**

```swift
private let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")!
private let pixellateFilter = CIFilter(name: "CIPixellate")!
private let posterizeFilter = CIFilter(name: "CIColorPosterize")!
```

**Step 2: Add Film Blur method (after `applyMotionBlur` method):**

```swift
// MARK: - Film Blur

private func applyFilmBlur(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent
    let maxDim = max(extent.width, extent.height)
    // Scale radius to resolution: 2-8px at proxy size
    let radius = (maxDim / 1200.0) * (2.0 + intensity * 6.0)

    gaussianBlurFilter.setValue(image, forKey: kCIInputImageKey)
    gaussianBlurFilter.setValue(radius, forKey: kCIInputRadiusKey)
    guard let blurred = gaussianBlurFilter.outputImage?.cropped(to: extent) else { return image }

    // Blend with original for cinematic softness (not full blur)
    return blendImages(original: image, filtered: blurred, intensity: intensity * 0.7)
}
```

**Step 3: Add Low-Res method:**

```swift
// MARK: - Low-Res

private func applyLowRes(to image: CIImage, intensity: Double) -> CIImage {
    let extent = image.extent
    let maxDim = max(extent.width, extent.height)

    // Pixellate: scale size to resolution (4-24px range)
    let pixelSize = (maxDim / 1200.0) * (4.0 + intensity * 20.0)
    pixellateFilter.setValue(image, forKey: kCIInputImageKey)
    pixellateFilter.setValue(pixelSize, forKey: kCIInputScaleKey)
    let center = CIVector(x: extent.midX, y: extent.midY)
    pixellateFilter.setValue(center, forKey: kCIInputCenterKey)
    guard let pixellated = pixellateFilter.outputImage else { return image }

    // Color posterize: reduce color levels (30 at 0% to 6 at 100%)
    let levels = max(6.0, 30.0 - intensity * 24.0)
    posterizeFilter.setValue(pixellated, forKey: kCIInputImageKey)
    posterizeFilter.setValue(levels, forKey: "inputLevels")
    let posterized = posterizeFilter.outputImage?.cropped(to: extent) ?? pixellated.cropped(to: extent)

    return blendImages(original: image, filtered: posterized, intensity: intensity)
}
```

**Step 4: Add calls in `applyEffects` method (before the letterbox block, around line 332):**

```swift
if state.filmBlurIntensity > 0 {
    result = applyFilmBlur(to: result, intensity: state.filmBlurIntensity)
}

if state.lowResIntensity > 0 {
    result = applyLowRes(to: result, intensity: state.lowResIntensity)
}
```

**Step 5: Commit**
```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat: implement film blur and low-res CIFilter pipelines"
```

---

### Task 7: Before/After Preview View

**Files:**
- Create: `Fotico/Views/Editor/BeforeAfterView.swift`
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Create BeforeAfterView.swift:**

```swift
import SwiftUI

struct BeforeAfterView: View {
    let originalCIImage: CIImage?
    let editedCIImage: CIImage?
    let onDismiss: () -> Void

    @State private var dividerPosition: CGFloat = 0.5  // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let dividerX = width * dividerPosition

            ZStack {
                // Edited image (full)
                if let edited = editedCIImage {
                    MetalImageView(ciImage: edited)
                        .ignoresSafeArea()
                }

                // Original image (clipped to left of divider)
                if let original = originalCIImage {
                    MetalImageView(ciImage: original)
                        .ignoresSafeArea()
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: dividerX)
                                Spacer(minLength: 0)
                            }
                        )
                }

                // Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .position(x: dividerX, y: geometry.size.height / 2)
                    .shadow(color: .black.opacity(0.5), radius: 2)

                // Divider handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.caption2.weight(.bold))
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundColor(.black)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: dividerX, y: geometry.size.height / 2)

                // Labels
                VStack {
                    HStack {
                        Text("ORIGINAL")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                            .padding(.leading, 12)

                        Spacer()

                        Text("EDITADO")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                            .padding(.trailing, 12)
                    }
                    .padding(.top, 12)

                    Spacer()
                }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dividerPosition = min(max(value.location.x / width, 0.02), 0.98)
                    }
            )
            .background(Color.black)
        }
    }
}
```

**Step 2: Add `@State private var showBeforeAfter = false` to MainEditorView (with other @State properties, around line 14):**

```swift
@State private var showBeforeAfter = false
```

**Step 3: Add eye button in topToolbar (in the Spacer area between undo/redo and the menu, or alongside undo/redo). Add after the redo button, inside the HStack(spacing: 16) around line 165:**

```swift
Button {
    showBeforeAfter = true
} label: {
    Image(systemName: "eye")
        .foregroundColor(!editorVM.editState.isDefault ? .white : .lumeDisabled)
        .frame(width: 44, height: 44)
}
.disabled(editorVM.editState.isDefault)
.accessibilityLabel("Antes/Después")
```

**Step 4: Add fullScreenCover for BeforeAfterView (after the existing `.fullScreenCover` for camera, around line 71):**

```swift
.fullScreenCover(isPresented: $showBeforeAfter) {
    if let original = editorVM.originalImage?.toCIImage() {
        BeforeAfterView(
            originalCIImage: original,
            editedCIImage: editorVM.editedCIImage,
            onDismiss: { showBeforeAfter = false }
        )
    }
}
```

**Step 5: Register BeforeAfterView.swift in project.pbxproj** — Add PBXFileReference, PBXBuildFile, and add to Editor group children and Sources build phase.

**Step 6: Commit**
```bash
git add Fotico/Views/Editor/BeforeAfterView.swift Fotico/Views/MainEditorView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add before/after comparison view with swipe divider"
```

---

### Task 8: Favorite Presets

**Files:**
- Modify: `Fotico/Views/Editor/PresetGridView.swift`

**Step 1: Add @AppStorage and computed property at the top of PresetGridView:**

```swift
@AppStorage("favoritePresetIds") private var favoritePresetIdsString: String = ""

private var favoritePresetIds: Set<String> {
    Set(favoritePresetIdsString.split(separator: ",").map(String.init))
}

private func toggleFavorite(_ presetId: String) {
    var ids = favoritePresetIds
    if ids.contains(presetId) {
        ids.remove(presetId)
    } else {
        ids.insert(presetId)
    }
    favoritePresetIdsString = ids.sorted().joined(separator: ",")
}

private var favoritePresets: [FilterPreset] {
    presets.filter { favoritePresetIds.contains($0.id) }
}
```

**Step 2: Add a "★ Favoritos" category chip BEFORE the ForEach in categoryChips. Insert after the "Todos" CategoryChipView:**

```swift
if !favoritePresets.isEmpty {
    CategoryChipView(name: "★ Favoritos", icon: "star.fill", isSelected: selectedCategory == nil && showFavoritesOnly) {
        showFavoritesOnly.toggle()
        if showFavoritesOnly { selectedCategory = nil }
    }
}
```

Actually, simpler approach — add a "Favoritos" pseudo-category. Use a @State bool:

```swift
@State private var showFavoritesOnly = false
```

And update `filteredPresets` to:

```swift
private var filteredPresets: [FilterPreset] {
    if showFavoritesOnly {
        return presets.filter { favoritePresetIds.contains($0.id) }
    }
    if let category = selectedCategory {
        return presets.filter { $0.category == category }
    }
    return presets
}
```

**Step 3: Add heart button overlay to each preset grid item. In `gridItem` function, add to the ZStack (alongside the PremiumBadge), at bottom-left:**

```swift
if id != nil {
    Button {
        HapticManager.impact(.light)
        toggleFavorite(id!)
    } label: {
        Image(systemName: favoritePresetIds.contains(id!) ? "heart.fill" : "heart")
            .font(.caption2)
            .foregroundColor(favoritePresetIds.contains(id!) ? .red : .white.opacity(0.7))
            .padding(4)
            .background(Color.black.opacity(0.4))
            .clipShape(Circle())
    }
    .offset(x: 3, y: -3)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
}
```

**Step 4: Add favorites chip in categoryChips. Before the ForEach:**

```swift
CategoryChipView(
    name: "★",
    icon: "star.fill",
    isSelected: showFavoritesOnly
) {
    showFavoritesOnly.toggle()
    if showFavoritesOnly { selectedCategory = nil }
}
```

And when selecting a regular category, turn off favorites:

In the existing ForEach for categories, update the action:
```swift
selectedCategory = category
showFavoritesOnly = false
```

And in the "Todos" chip:
```swift
selectedCategory = nil
showFavoritesOnly = false
```

**Step 5: Commit**
```bash
git add Fotico/Views/Editor/PresetGridView.swift
git commit -m "feat: add favorite presets with heart toggle and star filter"
```

---

### Task 9: Aspect Ratio Presets in CropView

**Files:**
- Modify: `Fotico/Views/Editor/CropView.swift`
- Modify: `Fotico/Models/EditState.swift`

**Step 1: Add CropAspectRatio enum to EditState.swift (after CropRect struct):**

```swift
enum CropAspectRatio: String, CaseIterable, Sendable, Codable {
    case free
    case square      // 1:1
    case portrait4x5 // 4:5
    case story9x16   // 9:16
    case landscape16x9 // 16:9
    case classic4x3  // 4:3

    var displayName: String {
        switch self {
        case .free: return "Libre"
        case .square: return "1:1"
        case .portrait4x5: return "4:5"
        case .story9x16: return "9:16"
        case .landscape16x9: return "16:9"
        case .classic4x3: return "4:3"
        }
    }

    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .portrait4x5: return 4.0 / 5.0
        case .story9x16: return 9.0 / 16.0
        case .landscape16x9: return 16.0 / 9.0
        case .classic4x3: return 4.0 / 3.0
        }
    }
}
```

**Step 2: Add property to EditState:**

```swift
var cropAspectRatio: CropAspectRatio = .free
```

**Step 3: Add aspect ratio chips to CropView. Add new properties and chips section before the rotation section:**

```swift
struct CropView: View {
    @Binding var rotation: Double
    @Binding var cropAspectRatio: CropAspectRatio
    var onRotationChanged: () -> Void
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Aspect Ratio chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CropAspectRatio.allCases, id: \.rawValue) { ratio in
                        Button {
                            HapticManager.selection()
                            onCommit()
                            cropAspectRatio = ratio
                        } label: {
                            Text(ratio.displayName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(cropAspectRatio == ratio ? Color.lumePrimary : Color.lumeSurface)
                                .foregroundColor(cropAspectRatio == ratio ? .black : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Existing rotation section...
```

**Step 4: Update CropView usage in MainEditorView.swift (around line 264):**

```swift
case .crop:
    CropView(
        rotation: $editorVM.editState.rotation,
        cropAspectRatio: $editorVM.editState.cropAspectRatio,
        onRotationChanged: { editorVM.updateRotation(editorVM.editState.rotation) },
        onCommit: { editorVM.commitRotation() }
    )
```

Note: The actual crop rect calculation based on aspect ratio would require an interactive crop rect UI, which is a larger feature. For now, the chips store the selected ratio in EditState for future use when an interactive crop UI is added. The aspect ratio will be applied during export if `cropAspectRatio != .free`.

**Step 5: Commit**
```bash
git add Fotico/Views/Editor/CropView.swift Fotico/Models/EditState.swift Fotico/Views/MainEditorView.swift
git commit -m "feat: add aspect ratio presets to crop view"
```

---

### Task 10: Color Tone (Split Toning)

**Files:**
- Modify: `Fotico/Models/EditState.swift`
- Create: `Fotico/Views/Editor/ColorTonePanelView.swift`
- Modify: `Fotico/Services/ImageFilterService.swift`
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Add Color Tone properties to EditState:**

```swift
// Color Tone (Split Toning)
var shadowToneHue: Double = 0.0           // 0.0...1.0 (hue wheel)
var shadowToneSaturation: Double = 0.0    // 0.0...1.0 (0 = off)
var highlightToneHue: Double = 0.0        // 0.0...1.0
var highlightToneSaturation: Double = 0.0 // 0.0...1.0
```

**Step 2: Add `colorTone` to EditorTool enum (in PhotoEditorViewModel.swift, after `.crop`):**

```swift
case colorTone

// Add displayName:
case .colorTone: return "Tono"

// Add icon:
case .colorTone: return "circle.lefthalf.filled"
```

**Step 3: Create ColorTonePanelView.swift:**

```swift
import SwiftUI

struct ColorTonePanelView: View {
    @Binding var editState: EditState
    let onUpdate: () -> Void
    let onCommit: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Shadows section
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                            .foregroundColor(.lumePrimary)
                        Text("Sombras")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if editState.shadowToneSaturation > 0 {
                            Circle()
                                .fill(Color(hue: editState.shadowToneHue, saturation: editState.shadowToneSaturation, brightness: 0.8))
                                .frame(width: 16, height: 16)
                        }
                    }

                    toneSlider(label: "Color", value: Binding(
                        get: { editState.shadowToneHue },
                        set: { editState.shadowToneHue = $0; onUpdate() }
                    ), range: 0...1, isHue: true)

                    toneSlider(label: "Intensidad", value: Binding(
                        get: { editState.shadowToneSaturation },
                        set: { editState.shadowToneSaturation = $0; onUpdate() }
                    ), range: 0...1, isHue: false)
                }

                Divider().background(Color.lumeTextSecondary.opacity(0.3))

                // Highlights section
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .font(.caption)
                            .foregroundColor(.lumePrimary)
                        Text("Luces")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if editState.highlightToneSaturation > 0 {
                            Circle()
                                .fill(Color(hue: editState.highlightToneHue, saturation: editState.highlightToneSaturation, brightness: 0.9))
                                .frame(width: 16, height: 16)
                        }
                    }

                    toneSlider(label: "Color", value: Binding(
                        get: { editState.highlightToneHue },
                        set: { editState.highlightToneHue = $0; onUpdate() }
                    ), range: 0...1, isHue: true)

                    toneSlider(label: "Intensidad", value: Binding(
                        get: { editState.highlightToneSaturation },
                        set: { editState.highlightToneSaturation = $0; onUpdate() }
                    ), range: 0...1, isHue: false)
                }

                // Reset button
                if editState.shadowToneSaturation > 0 || editState.highlightToneSaturation > 0 {
                    Button {
                        onCommit()
                        editState.shadowToneHue = 0
                        editState.shadowToneSaturation = 0
                        editState.highlightToneHue = 0
                        editState.highlightToneSaturation = 0
                        onUpdate()
                    } label: {
                        Label("Restablecer", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.lumeWarning)
                    }
                }
            }
            .padding()
        }
    }

    private func toneSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, isHue: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 65, alignment: .leading)

            if isHue {
                // Rainbow gradient background for hue slider
                Slider(value: value, in: range, step: 0.01)
                    .tint(Color(hue: value.wrappedValue, saturation: 0.8, brightness: 0.9))
            } else {
                Slider(value: value, in: range, step: 0.01)
                    .tint(.lumePrimary)
            }

            Text("\(Int(value.wrappedValue * 100))")
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.lumeTextSecondary)
                .frame(width: 30)
        }
    }
}
```

**Step 4: Implement split toning in ImageFilterService. Add method:**

```swift
// MARK: - Color Tone (Split Toning)

private func applyColorTone(to image: CIImage, state: EditState) -> CIImage {
    let hasShadowTone = state.shadowToneSaturation > 0
    let hasHighlightTone = state.highlightToneSaturation > 0
    guard hasShadowTone || hasHighlightTone else { return image }

    var result = image
    let extent = image.extent

    if hasShadowTone {
        // Create shadow tint color
        let h = state.shadowToneHue
        let s = state.shadowToneSaturation
        // Convert HSB to RGB
        let (r, g, b) = hsbToRGB(h: h, s: s, b: 0.3)

        // Create solid color
        let colorGen = CIFilter(name: "CIConstantColorGenerator")!
        colorGen.setValue(CIColor(red: r, green: g, blue: b, alpha: 1), forKey: kCIInputColorKey)
        guard let tintImage = colorGen.outputImage?.cropped(to: extent) else { return result }

        // Blend in shadow regions using multiply (affects darks)
        let multiply = CIFilter(name: "CIMultiplyBlendMode")!
        multiply.setValue(tintImage, forKey: kCIInputImageKey)
        multiply.setValue(result, forKey: kCIInputBackgroundImageKey)
        if let multiplied = multiply.outputImage?.cropped(to: extent) {
            result = blendImages(original: result, filtered: multiplied, intensity: s * 0.4)
        }
    }

    if hasHighlightTone {
        let h = state.highlightToneHue
        let s = state.highlightToneSaturation
        let (r, g, b) = hsbToRGB(h: h, s: s, b: 0.9)

        let colorGen = CIFilter(name: "CIConstantColorGenerator")!
        colorGen.setValue(CIColor(red: r, green: g, blue: b, alpha: 1), forKey: kCIInputColorKey)
        guard let tintImage = colorGen.outputImage?.cropped(to: extent) else { return result }

        // Screen blend for highlights (affects brights)
        let screen = CIFilter(name: "CIScreenBlendMode")!
        screen.setValue(tintImage, forKey: kCIInputImageKey)
        screen.setValue(result, forKey: kCIInputBackgroundImageKey)
        if let screened = screen.outputImage?.cropped(to: extent) {
            result = blendImages(original: result, filtered: screened, intensity: s * 0.3)
        }
    }

    return result
}

private func hsbToRGB(h: Double, s: Double, b: Double) -> (CGFloat, CGFloat, CGFloat) {
    let c = b * s
    let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
    let m = b - c
    let (r1, g1, b1): (Double, Double, Double)
    switch Int(h * 6) % 6 {
    case 0: (r1, g1, b1) = (c, x, 0)
    case 1: (r1, g1, b1) = (x, c, 0)
    case 2: (r1, g1, b1) = (0, c, x)
    case 3: (r1, g1, b1) = (0, x, c)
    case 4: (r1, g1, b1) = (x, 0, c)
    default: (r1, g1, b1) = (c, 0, x)
    }
    return (CGFloat(r1 + m), CGFloat(g1 + m), CGFloat(b1 + m))
}
```

**Step 5: Call applyColorTone in `applyAdjustments` (at the end, after clarity):**

```swift
// Color Tone (Split Toning)
result = applyColorTone(to: result, state: state)
```

**Step 6: Add to MainEditorView's toolPanel switch and panelHeight:**

```swift
case .colorTone:
    ColorTonePanelView(editState: $editorVM.editState) {
        editorVM.updateAdjustment()
    } onCommit: {
        editorVM.commitAdjustment()
    }

// In panelHeight:
case .colorTone: return screenHeight * 0.30
```

**Step 7: Register ColorTonePanelView.swift in project.pbxproj**

**Step 8: Commit**
```bash
git add Fotico/Models/EditState.swift Fotico/Views/Editor/ColorTonePanelView.swift Fotico/Services/ImageFilterService.swift Fotico/ViewModels/PhotoEditorViewModel.swift Fotico/Views/MainEditorView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add Color Tone split toning with shadow/highlight hue controls"
```

---

### Task 11: HSL Panel with Metal Shader

**Files:**
- Modify: `Fotico/Models/EditState.swift`
- Create: `Fotico/Metal/HSLShader.metal`
- Modify: `Fotico/Services/MetalKernelService.swift`
- Modify: `Fotico/Services/ImageFilterService.swift`
- Create: `Fotico/Views/Editor/HSLPanelView.swift`
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Add HSL data struct and properties to EditState.swift:**

```swift
struct HSLAdjustment: Sendable, Equatable, Codable {
    var hue: Double = 0.0         // -0.5...0.5 (shift)
    var saturation: Double = 0.0  // -1.0...1.0
    var luminance: Double = 0.0   // -1.0...1.0

    var isDefault: Bool {
        hue == 0 && saturation == 0 && luminance == 0
    }
}

enum HSLColorRange: String, CaseIterable, Sendable, Codable {
    case red, orange, yellow, green, cyan, blue, purple, magenta

    var displayName: String {
        switch self {
        case .red: return "Rojo"
        case .orange: return "Naranja"
        case .yellow: return "Amarillo"
        case .green: return "Verde"
        case .cyan: return "Cian"
        case .blue: return "Azul"
        case .purple: return "Púrpura"
        case .magenta: return "Magenta"
        }
    }

    var displayColor: (Double, Double, Double) {  // hue, saturation, brightness
        switch self {
        case .red: return (0.0, 0.9, 0.9)
        case .orange: return (0.08, 0.9, 0.9)
        case .yellow: return (0.17, 0.9, 0.9)
        case .green: return (0.33, 0.8, 0.8)
        case .cyan: return (0.5, 0.8, 0.9)
        case .blue: return (0.67, 0.8, 0.9)
        case .purple: return (0.75, 0.7, 0.8)
        case .magenta: return (0.83, 0.8, 0.9)
        }
    }

    /// Hue center in 0-1 range for the Metal shader
    var hueCenter: Float {
        switch self {
        case .red: return 0.0
        case .orange: return 0.083
        case .yellow: return 0.167
        case .green: return 0.333
        case .cyan: return 0.5
        case .blue: return 0.667
        case .purple: return 0.75
        case .magenta: return 0.833
        }
    }
}
```

Add property to EditState:

```swift
// HSL
var hslAdjustments: [HSLColorRange: HSLAdjustment] = [:]
```

**Step 2: Create HSLShader.metal:**

```metal
#include <metal_stdlib>
using namespace metal;

struct HSLParams {
    float hueCenters[8];     // Center hue for each range (0-1)
    float hueShifts[8];      // Hue shift (-0.5 to 0.5)
    float satShifts[8];      // Saturation shift (-1 to 1)
    float lumShifts[8];      // Luminance shift (-1 to 1)
    uint activeCount;         // Number of active adjustments
};

// RGB to HSL conversion
float3 rgbToHsl(float3 rgb) {
    float maxC = max(max(rgb.r, rgb.g), rgb.b);
    float minC = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxC - minC;

    float h = 0.0;
    float s = 0.0;
    float l = (maxC + minC) * 0.5;

    if (delta > 0.0001) {
        s = l < 0.5 ? delta / (maxC + minC) : delta / (2.0 - maxC - minC);

        if (maxC == rgb.r) {
            h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
        } else if (maxC == rgb.g) {
            h = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            h = (rgb.r - rgb.g) / delta + 4.0;
        }
        h /= 6.0;
    }

    return float3(h, s, l);
}

// HSL to RGB conversion
float3 hslToRgb(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (s < 0.0001) {
        return float3(l, l, l);
    }

    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;

    auto hue2rgb = [](float p, float q, float t) -> float {
        if (t < 0.0) t += 1.0;
        if (t > 1.0) t -= 1.0;
        if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
        if (t < 1.0/2.0) return q;
        if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
        return p;
    };

    return float3(
        hue2rgb(p, q, h + 1.0/3.0),
        hue2rgb(p, q, h),
        hue2rgb(p, q, h - 1.0/3.0)
    );
}

// Smooth weight for how much a pixel's hue matches a target range
float hueWeight(float pixelHue, float targetHue, float width) {
    float dist = abs(pixelHue - targetHue);
    dist = min(dist, 1.0 - dist); // Wrap around
    return smoothstep(width, 0.0, dist);
}

kernel void hslAdjustKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant HSLParams &params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float4 pixel = inTexture.read(gid);
    float3 hsl = rgbToHsl(pixel.rgb);

    float hueWidth = 0.06; // Each range covers ~43° of the hue wheel

    for (uint i = 0; i < params.activeCount; i++) {
        float w = hueWeight(hsl.x, params.hueCenters[i], hueWidth);
        if (w > 0.001) {
            hsl.x += params.hueShifts[i] * w;
            hsl.y = clamp(hsl.y + params.satShifts[i] * w, 0.0, 1.0);
            hsl.z = clamp(hsl.z + params.lumShifts[i] * w, 0.0, 1.0);
        }
    }

    // Wrap hue
    hsl.x = fract(hsl.x);

    float3 rgb = hslToRgb(hsl);
    outTexture.write(float4(rgb, pixel.a), gid);
}
```

**Step 3: Add HSL pipeline to MetalKernelService.** Read MetalKernelService.swift first to understand the pattern, then add:

- A `hslPipelineState: MTLComputePipelineState?` property
- Initialize it from the "hslAdjustKernel" function
- An `applyHSL(to:params:)` method that dispatches the compute shader

**Step 4: Add `hsl` tool to EditorTool:**

```swift
case hsl

// displayName:
case .hsl: return "HSL"

// icon:
case .hsl: return "circle.hexagongrid"
```

**Step 5: Create HSLPanelView.swift with color selector chips + H/S/L sliders.**

**Step 6: Wire into ImageFilterService (call after adjustments, before effects).**

**Step 7: Add to MainEditorView toolPanel switch.**

**Step 8: Register new files in project.pbxproj.**

**Step 9: Commit**
```bash
git add Fotico/Models/EditState.swift Fotico/Metal/HSLShader.metal Fotico/Services/MetalKernelService.swift Fotico/Services/ImageFilterService.swift Fotico/Views/Editor/HSLPanelView.swift Fotico/ViewModels/PhotoEditorViewModel.swift Fotico/Views/MainEditorView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add HSL per-color adjustment panel with Metal shader"
```

---

### Task 12: Edges/Borders (Overlay Category)

**Files:**
- Modify: `Fotico/Models/OverlayAsset.swift`

**Step 1: Add `edges` case to OverlayCategory:**

```swift
case edges

// displayName:
case .edges: return "Bordes"

// icon:
case .edges: return "rectangle.dashed"
```

**Step 2: Add edge overlay assets to allOverlays array. These will use programmatically generated borders since we don't have PNG assets. For now, add placeholder entries that we'll generate:**

```swift
// Edges
OverlayAsset(id: "edge_polaroid_border", displayName: "Polaroid", category: .edges, fileName: "edge_polaroid_border", tier: .free, sortOrder: 50),
OverlayAsset(id: "edge_35mm_border", displayName: "35mm", category: .edges, fileName: "edge_35mm_border", tier: .free, sortOrder: 51),
OverlayAsset(id: "edge_inset", displayName: "Inset", category: .edges, fileName: "edge_inset", tier: .free, sortOrder: 52),
OverlayAsset(id: "edge_round", displayName: "Redondo", category: .edges, fileName: "edge_round", tier: .free, sortOrder: 53),
```

**Step 3: Create a Python script `scripts/generate_edge_overlays.py` that generates 4 border PNG images (1200x1600, transparent center, opaque borders) with different styles. These get saved to `Fotico/Resources/`.**

**Step 4: Add the generated PNGs to the Xcode asset catalog or Resources.**

**Step 5: Commit**
```bash
git add Fotico/Models/OverlayAsset.swift scripts/generate_edge_overlays.py Fotico/Resources/
git commit -m "feat: add edges/borders overlay category with 4 border styles"
```

---

### Task 13: Text Tool (Basic)

This is a complex feature. For an MVP:

**Files:**
- Modify: `Fotico/Models/EditState.swift`
- Create: `Fotico/Views/Editor/TextOverlayView.swift`
- Create: `Fotico/Views/Editor/TextToolPanelView.swift`
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`
- Modify: `Fotico/Services/ImageFilterService.swift`
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Add TextLayer model to EditState.swift:**

```swift
struct TextLayer: Sendable, Equatable, Codable, Identifiable {
    let id: String
    var text: String = "Texto"
    var style: TextStyle = .minimal
    var color: TextColor = .white
    var positionX: Double = 0.5  // normalized 0-1
    var positionY: Double = 0.5
    var scale: Double = 1.0
    var rotation: Double = 0.0   // radians
}

enum TextStyle: String, CaseIterable, Sendable, Codable {
    case minimal    // SF Pro, light weight
    case editorial  // SF Pro, bold, uppercase, wide tracking
    case mono       // SF Mono, medium
    case analog     // New York (serif), italic

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .editorial: return "Editorial"
        case .mono: return "Mono"
        case .analog: return "Análogo"
        }
    }
}

enum TextColor: String, CaseIterable, Sendable, Codable {
    case white, black, cream, red

    var uiColor: (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .white: return (1, 1, 1)
        case .black: return (0, 0, 0)
        case .cream: return (0.96, 0.93, 0.87)
        case .red: return (0.9, 0.2, 0.15)
        }
    }
}
```

**Step 2: Add to EditState:**

```swift
var textLayers: [TextLayer] = []
```

**Step 3: Add `text` tool to EditorTool:**

```swift
case text

// displayName:
case .text: return "Texto"

// icon:
case .text: return "textformat"
```

**Step 4: Create TextToolPanelView with text input, style picker, color picker, and add/remove buttons.**

**Step 5: Create TextOverlayView — a draggable/pinchable overlay showing text labels on the image preview.**

**Step 6: Render text layers in ImageFilterService using CGContext text drawing → CIImage compositing.**

**Step 7: Wire into MainEditorView.**

**Step 8: Register new files in project.pbxproj.**

**Step 9: Commit**
```bash
git add Fotico/Models/EditState.swift Fotico/Views/Editor/TextOverlayView.swift Fotico/Views/Editor/TextToolPanelView.swift Fotico/ViewModels/PhotoEditorViewModel.swift Fotico/Services/ImageFilterService.swift Fotico/Views/MainEditorView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add text tool with 4 curated styles and drag positioning"
```

---

### Task 14: Labbet Link (Shareable Edits)

**Files:**
- Create: `Fotico/Services/EditShareService.swift`
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Create EditShareService.swift:**

```swift
import Foundation
import UIKit

struct EditShareService {
    static func shareURL(from editState: EditState) -> URL? {
        guard let data = try? JSONEncoder().encode(editState) else { return nil }
        let base64 = data.base64EncodedString()
        guard let encoded = base64.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "lume://edit?data=\(encoded)")
    }

    static func editState(from url: URL) -> EditState? {
        guard url.scheme == "lume",
              url.host == "edit",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataParam) else { return nil }
        return try? JSONDecoder().decode(EditState.self, from: data)
    }

    @MainActor
    static func presentShareSheet(editState: EditState) {
        guard let url = shareURL(from: editState) else { return }
        let text = "¡Mira mi edición en Lumé! \(url.absoluteString)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        rootVC.present(activityVC, animated: true)
    }
}
```

**Step 2: Add "Compartir edición" to the More menu in MainEditorView's topToolbar (in the Menu block, after "Guardar proyecto"):**

```swift
Button {
    EditShareService.presentShareSheet(editState: editorVM.editState)
} label: {
    Label("Compartir edición", systemImage: "square.and.arrow.up")
}
.disabled(editorVM.editState.isDefault)
```

**Step 3: Register EditShareService.swift in project.pbxproj.**

**Step 4: Commit**
```bash
git add Fotico/Services/EditShareService.swift Fotico/Views/MainEditorView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add shareable edit links via Labbet Link style sharing"
```

---

### Task 15: Final Build Verification & Cleanup

**Step 1: Run clean build:**

```bash
xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`

**Step 2: Fix any compilation errors if present.**

**Step 3: Final commit if fixes were needed:**

```bash
git add -A
git commit -m "fix: resolve compilation issues from improvements pack"
```

---

## Parallelization Guide

These tasks can be grouped for parallel execution:

- **Parallel Group A (Models):** Tasks 1, 4, 9 (EditState additions) — MUST run first, but can be combined into one subagent
- **Parallel Group B (Services):** Tasks 2, 6 (ImageFilterService) — depends on Group A
- **Parallel Group C (Views):** Tasks 3, 7, 8 (AdjustmentPanel, BeforeAfter, PresetGrid) — depends on Group A
- **Parallel Group D (ViewModel):** Task 5 (ViewModel switches) — depends on Group A
- **Parallel Group E (Advanced):** Tasks 10, 11, 12, 13, 14 — mostly independent of each other, depend on Group A

**Recommended execution order:**
1. Tasks 1 + 4 + 9 combined (all EditState changes)
2. Tasks 2 + 5 + 6 in parallel (services + ViewModel)
3. Tasks 3 + 7 + 8 in parallel (simple views)
4. Tasks 10 + 11 + 12 + 13 + 14 in parallel (advanced features)
5. Task 15 (build verification)
