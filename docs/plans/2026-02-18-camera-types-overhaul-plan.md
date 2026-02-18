# Camera Types + Editor Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Overhaul the camera to use "camera types" (Disposable, Polaroid, 35mm, etc.) with a Tezza-style toolbar, and add 5 featured LUT filters to the editor.

**Architecture:** Create a new `CameraType` model separate from `FilterPreset`. Replace the current Normal/Film mode toggle + filter sheet with a horizontal camera type strip + bottom toolbar tabs. Generate 5 new LUT files for the editor's featured category. Camera types reuse existing LUT files.

**Tech Stack:** Swift, SwiftUI, CoreImage, LUT .cube files, Python (LUT generation)

---

## Phase 1: Editor Featured Filters

### Task 1: Generate 5 featured LUT files

**Files:**
- Create: `Fotico/Resources/LUTs/soft_aesthetic.cube`
- Create: `Fotico/Resources/LUTs/golden_hour.cube`
- Create: `Fotico/Resources/LUTs/clean_girl.cube`
- Create: `Fotico/Resources/LUTs/vintage_film.cube`
- Create: `Fotico/Resources/LUTs/moody_deep.cube`

**Step 1: Generate all 5 LUTs with Python**

Write and run a Python script that generates 33x33x33 .cube LUTs using the Gemini specs:

1. **soft_aesthetic.cube** — "Soft Aesthetic" (dulce y luminoso)
   - Exposure: +0.5 (brightness lift in highlights)
   - Contrast: -20 (flatten the S-curve)
   - Highlights: -30 (pull down highlights)
   - Shadows: +40 (lift shadows significantly)
   - Temperature: +5 (slightly warm)
   - Saturation: -10 (slight desaturation)
   - Clarity: -15 (soften texture — lower midtone contrast)

2. **golden_hour.cube** — "Golden Hour Vibes"
   - Temperature: +20 (strong warm shift)
   - Tint: +10 (toward pink)
   - Contrast: +10 (mild S-curve boost)
   - Shadows: +15 (lift shadows)
   - Orange luminance: +20 (skin illumination — boost orange/warm midtones)
   - Blue saturation: -30 (kill blue competition)

3. **clean_girl.cube** — "Clean Girl / Minimalist"
   - Exposure: +0.3 (slight brightening)
   - Contrast: +5 (very mild)
   - Whites: +20 (push highlights brighter)
   - Blacks: -10 (deeper blacks for definition)
   - Saturation: -15 (near-desaturated)
   - Vibrance: +5 (protect skin tones)
   - Clarity: +10 (sharper edges — boost midtone contrast)

4. **vintage_film.cube** — "Vintage Film" (90s aesthetic)
   - Contrast: -15 (flatten)
   - Shadows: +20 (lift shadows)
   - Black point lifted (matte/washed look — raise minimum output)
   - Temperature: +10 (warm)
   - Red saturation: +10 (lips/cheeks emphasis)
   - Global desaturation except warm tones

5. **moody_deep.cube** — "Moody Deep" (cinematographic)
   - Exposure: -0.5 (darken)
   - Contrast: +25 (strong S-curve)
   - Shadows: -15 (crush shadows)
   - Highlights: -50 (protect highlights from blowing)
   - Saturation: -20 (desaturated)
   - Vignette: built into LUT via radial luminance falloff
   - Green saturation: -80 (dead greens, editorial look)

Output all 5 files to `Fotico/Resources/LUTs/`.

**Step 2: Commit**

```bash
git add Fotico/Resources/LUTs/soft_aesthetic.cube Fotico/Resources/LUTs/golden_hour.cube Fotico/Resources/LUTs/clean_girl.cube Fotico/Resources/LUTs/vintage_film.cube Fotico/Resources/LUTs/moody_deep.cube
git commit -m "feat: add 5 featured editor LUT files (Soft, Golden, Clean, Film, Moody)"
```

---

### Task 2: Add featured category and 5 preset entries

**Files:**
- Modify: `Fotico/Models/FilterPreset.swift:112-135` (PresetCategory enum)
- Modify: `Fotico/Models/FilterPreset.swift:39-107` (allPresets array)

**Step 1: Add `featured` case to PresetCategory**

In `Fotico/Models/FilterPreset.swift`, add `featured` as the FIRST case in the enum (so it appears first in `CaseIterable`):

```swift
enum PresetCategory: String, CaseIterable, Sendable {
    case featured
    case cleanGirl
    case soft
    case film
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .featured: return "Featured"
        case .cleanGirl: return "Clean Girl"
        case .soft: return "Soft"
        case .film: return "Film"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .cleanGirl: return "sparkles"
        case .soft: return "cloud.fill"
        case .film: return "film"
        case .vintage: return "clock.arrow.circlepath"
        }
    }
}
```

**Step 2: Add 5 featured presets at the TOP of allPresets**

Insert before the Clean Girl section in the `allPresets` array:

```swift
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Featured
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    FilterPreset(id: "soft_aesthetic", name: "Soft", displayName: "Soft",
                 category: .featured, tier: .free, lutFileName: "soft_aesthetic.cube", sortOrder: -500),
    FilterPreset(id: "golden_hour", name: "Golden", displayName: "Golden",
                 category: .featured, tier: .free, lutFileName: "golden_hour.cube", sortOrder: -400),
    FilterPreset(id: "clean_girl_feat", name: "Clean", displayName: "Clean",
                 category: .featured, tier: .free, lutFileName: "clean_girl.cube", sortOrder: -300),
    FilterPreset(id: "vintage_film", name: "Film", displayName: "Film",
                 category: .featured, tier: .free, lutFileName: "vintage_film.cube", sortOrder: -200),
    FilterPreset(id: "moody_deep", name: "Moody", displayName: "Moody",
                 category: .featured, tier: .free, lutFileName: "moody_deep.cube", sortOrder: -100),
```

**Step 3: Commit**

```bash
git add Fotico/Models/FilterPreset.swift
git commit -m "feat: add Featured category with 5 editor presets (Soft, Golden, Clean, Film, Moody)"
```

---

### Task 3: Add 5 new LUT files to Xcode project

**Files:**
- Modify: `Fotico.xcodeproj/project.pbxproj`

**Step 1: Add entries for all 5 .cube files**

Search the pbxproj for an existing .cube file entry (e.g., `cocoa.cube`) to understand the pattern. For each of the 5 new files, add entries in:
- PBXBuildFile section
- PBXFileReference section
- PBXGroup (LUTs children array)
- PBXResourcesBuildPhase (files array)

Use unique 24-character hex IDs that don't conflict with existing ones.

**Step 2: Commit**

```bash
git add Fotico.xcodeproj/project.pbxproj
git commit -m "chore: add 5 featured LUT files to Xcode project"
```

---

### Task 4: Build and verify Phase 1

**Step 1: Build**

```bash
xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED

**Step 2: Fix any issues and commit**

---

## Phase 2: Camera Types Model + Data

### Task 5: Create CameraType model

**Files:**
- Create: `Fotico/Models/CameraType.swift`

**Step 1: Create the CameraType struct**

```swift
import Foundation

struct CameraType: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String              // SF Symbol name
    let lutFileName: String?      // nil = Normal (no filter)
    let grainIntensity: Double    // 0 = no grain
    let vignetteIntensity: Double // 0 = no vignette
    let bloomIntensity: Double    // 0 = no bloom
    let lightLeakEnabled: Bool

    static let allTypes: [CameraType] = [
        CameraType(id: "normal", name: "Normal", icon: "camera",
                   lutFileName: nil,
                   grainIntensity: 0, vignetteIntensity: 0, bloomIntensity: 0, lightLeakEnabled: false),

        CameraType(id: "disposable", name: "Disposable", icon: "camera.compact",
                   lutFileName: "disposable.cube",
                   grainIntensity: 0.3, vignetteIntensity: 1.5, bloomIntensity: 0, lightLeakEnabled: true),

        CameraType(id: "polaroid", name: "Polaroid", icon: "camera.viewfinder",
                   lutFileName: "polaroid.cube",
                   grainIntensity: 0.05, vignetteIntensity: 0.8, bloomIntensity: 0, lightLeakEnabled: false),

        CameraType(id: "film35mm", name: "35mm", icon: "camera.aperture",
                   lutFileName: "portra.cube",
                   grainIntensity: 0.15, vignetteIntensity: 0.3, bloomIntensity: 0, lightLeakEnabled: false),

        CameraType(id: "fuji400", name: "Fuji 400", icon: "camera.circle",
                   lutFileName: "fuji_400h.cube",
                   grainIntensity: 0.1, vignetteIntensity: 0.2, bloomIntensity: 0, lightLeakEnabled: false),

        CameraType(id: "super8", name: "Super8", icon: "film",
                   lutFileName: "super8.cube",
                   grainIntensity: 0.4, vignetteIntensity: 1.2, bloomIntensity: 0, lightLeakEnabled: false),

        CameraType(id: "glow", name: "Glow", icon: "sparkle",
                   lutFileName: "honey.cube",
                   grainIntensity: 0, vignetteIntensity: 0, bloomIntensity: 0.3, lightLeakEnabled: false),

        CameraType(id: "nocturna", name: "Nocturna", icon: "moon.fill",
                   lutFileName: "carbon.cube",
                   grainIntensity: 0.15, vignetteIntensity: 0.6, bloomIntensity: 0, lightLeakEnabled: false),
    ]
}
```

**Step 2: Commit**

```bash
git add Fotico/Models/CameraType.swift
git commit -m "feat: add CameraType model with 8 camera types"
```

---

### Task 6: Update CameraViewModel to use CameraType

**Files:**
- Modify: `Fotico/ViewModels/CameraViewModel.swift`

**Step 1: Replace FilterPreset references with CameraType**

Key changes to `CameraViewModel`:

1. Remove `CameraMode` enum entirely (no longer needed — "Normal" is just a camera type)
2. Replace `selectedPreset: FilterPreset?` with `selectedCameraType: CameraType`
3. Replace `cameraMode: CameraMode` — no longer needed
4. Remove `grainOnPreview` — grain is now per-camera-type
5. Update `processPreviewFrame` to use CameraType
6. Update `capturePhoto` to use CameraType
7. Remove `toggleMode()` and `selectPreset()`
8. Add `selectCameraType(_ type: CameraType)`

Replace the `processPreviewFrame` logic:

```swift
// In processPreviewFrame, replace the film mode block:
let cameraType = selectedCameraType
// ...
if let lutFileName = cameraType.lutFileName {
    result = CameraFilters.applyLivePreset(lutFileName: lutFileName, to: result)
}
if cameraType.grainIntensity > 0 {
    result = CameraFilters.addFilmGrain(to: result, intensity: CGFloat(cameraType.grainIntensity * 0.15))
}
if cameraType.vignetteIntensity > 0 {
    result = CameraFilters.addVignette(to: result, intensity: CGFloat(cameraType.vignetteIntensity))
}
if cameraType.bloomIntensity > 0 {
    result = CameraFilters.addBloom(to: result, intensity: CGFloat(cameraType.bloomIntensity))
}
if cameraType.lightLeakEnabled {
    result = CameraFilters.addLightLeak(to: result, intensity: 0.4)
}
```

**Step 2: Update CameraFilters enum**

Add new static methods for vignette, bloom, and light leak effects. Simplify `applyLivePreset` to take a `lutFileName` string instead of a full `FilterPreset`:

```swift
static func applyLivePreset(lutFileName: String, to image: CIImage) -> CIImage {
    return LUTService.shared.applyLUT(named: lutFileName, to: image, intensity: 1.0)
}

static func addVignette(to image: CIImage, intensity: CGFloat) -> CIImage {
    let vignette = CIFilter(name: "CIVignette")!
    vignette.setValue(image, forKey: kCIInputImageKey)
    vignette.setValue(intensity, forKey: kCIInputIntensityKey)
    vignette.setValue(1.5, forKey: kCIInputRadiusKey)
    return vignette.outputImage ?? image
}

static func addBloom(to image: CIImage, intensity: CGFloat) -> CIImage {
    let extent = image.extent
    let bloom = CIFilter(name: "CIBloom")!
    bloom.setValue(image, forKey: kCIInputImageKey)
    bloom.setValue(intensity, forKey: kCIInputIntensityKey)
    bloom.setValue(10.0, forKey: kCIInputRadiusKey)
    return bloom.outputImage?.cropped(to: extent) ?? image
}

static func addLightLeak(to image: CIImage, intensity: CGFloat) -> CIImage {
    let extent = image.extent
    let gradient = CIFilter(name: "CIRadialGradient")!
    gradient.setValue(CIVector(x: extent.width * 0.8, y: extent.height * 0.7), forKey: "inputCenter")
    gradient.setValue(extent.width * 0.2, forKey: "inputRadius0")
    gradient.setValue(extent.width * 0.6, forKey: "inputRadius1")
    gradient.setValue(CIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: Double(intensity)), forKey: "inputColor0")
    gradient.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")
    guard let gradientImage = gradient.outputImage?.cropped(to: extent) else { return image }

    let blend = CIFilter(name: "CIScreenBlendMode")!
    blend.setValue(image, forKey: kCIInputImageKey)
    blend.setValue(gradientImage, forKey: kCIInputBackgroundImageKey)
    return blend.outputImage ?? image
}
```

Update `capturePhoto`, `standardProcess`, and `vintageFlashProcess` to use `CameraType` instead of `FilterPreset`.

**Step 3: Commit**

```bash
git add Fotico/ViewModels/CameraViewModel.swift
git commit -m "refactor: update CameraViewModel to use CameraType instead of FilterPreset"
```

---

## Phase 3: Camera UI Overhaul

### Task 7: Create CameraTypeStripView

**Files:**
- Create: `Fotico/Views/Camera/CameraTypeStripView.swift`

**Step 1: Build horizontal scrollable strip with camera icons**

```swift
import SwiftUI

struct CameraTypeStripView: View {
    let cameraTypes: [CameraType]
    let selectedId: String
    let onSelect: (CameraType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(cameraTypes) { cameraType in
                    Button {
                        HapticManager.selection()
                        onSelect(cameraType)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: cameraType.icon)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)

                            Text(cameraType.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedId == cameraType.id ? Color.foticoPrimary : .white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
```

**Step 2: Commit**

```bash
git add Fotico/Views/Camera/CameraTypeStripView.swift
git commit -m "feat: add CameraTypeStripView component"
```

---

### Task 8: Create CameraToolbarView

**Files:**
- Create: `Fotico/Views/Camera/CameraToolbarView.swift`

**Step 1: Build bottom toolbar with tabs**

The toolbar has 5 tabs: Frame, Grid, Texture, FX, Flash. Each tab shows a small panel of options when selected.

```swift
import SwiftUI

enum CameraToolbarTab: String, CaseIterable {
    case frame, grid, texture, fx, flash

    var icon: String {
        switch self {
        case .frame: return "square"
        case .grid: return "grid"
        case .texture: return "line.3.horizontal"
        case .fx: return "fx"
        case .flash: return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .frame: return "Frame"
        case .grid: return "Grid"
        case .texture: return "Texture"
        case .fx: return "FX"
        case .flash: return "Flash"
        }
    }
}

struct CameraToolbarView: View {
    @Binding var selectedTab: CameraToolbarTab?
    @Binding var selectedFrame: String?       // overlay asset id or nil
    @Binding var gridMode: GridMode
    @Binding var grainLevel: GrainLevel
    @Binding var lightLeakOn: Bool
    @Binding var vignetteOn: Bool
    @Binding var bloomOn: Bool
    let flashMode: FlashMode
    let onFlashCycle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Expanded panel for selected tab
            if let tab = selectedTab {
                tabPanel(for: tab)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Tab bar
            HStack(spacing: 0) {
                ForEach(CameraToolbarTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = selectedTab == tab ? nil : tab
                        }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.label)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Color.foticoPrimary : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
        }
    }

    @ViewBuilder
    private func tabPanel(for tab: CameraToolbarTab) -> some View {
        switch tab {
        case .frame:
            frameOptions
        case .grid:
            gridOptions
        case .texture:
            textureOptions
        case .fx:
            fxOptions
        case .flash:
            flashOptions
        }
    }

    // Frame options: None, Polaroid, 35mm, Super8
    private var frameOptions: some View {
        HStack(spacing: 16) {
            frameChip("None", id: nil)
            frameChip("Polaroid", id: "frame_polaroid")
            frameChip("35mm", id: "frame_35mm")
            frameChip("Super8", id: "frame_super8")
        }
        .padding(.horizontal, 16)
    }

    private func frameChip(_ name: String, id: String?) -> some View {
        Button {
            selectedFrame = id
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFrame == id ? Color.foticoPrimary : Color.white.opacity(0.15))
                .foregroundColor(selectedFrame == id ? .black : .white)
                .cornerRadius(14)
        }
    }

    // Grid options
    private var gridOptions: some View {
        HStack(spacing: 16) {
            gridChip("Off", mode: .off)
            gridChip("Thirds", mode: .thirds)
            gridChip("Center", mode: .center)
            gridChip("Golden", mode: .golden)
        }
        .padding(.horizontal, 16)
    }

    private func gridChip(_ name: String, mode: GridMode) -> some View {
        Button {
            gridMode = mode
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(gridMode == mode ? Color.foticoPrimary : Color.white.opacity(0.15))
                .foregroundColor(gridMode == mode ? .black : .white)
                .cornerRadius(14)
        }
    }

    // Texture / grain options
    private var textureOptions: some View {
        HStack(spacing: 16) {
            grainChip("Off", level: .off)
            grainChip("Light", level: .light)
            grainChip("Medium", level: .medium)
            grainChip("Heavy", level: .heavy)
        }
        .padding(.horizontal, 16)
    }

    private func grainChip(_ name: String, level: GrainLevel) -> some View {
        Button {
            grainLevel = level
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(grainLevel == level ? Color.foticoPrimary : Color.white.opacity(0.15))
                .foregroundColor(grainLevel == level ? .black : .white)
                .cornerRadius(14)
        }
    }

    // FX options
    private var fxOptions: some View {
        HStack(spacing: 16) {
            fxToggle("Light Leak", on: lightLeakOn) { lightLeakOn.toggle() }
            fxToggle("Vignette", on: vignetteOn) { vignetteOn.toggle() }
            fxToggle("Bloom", on: bloomOn) { bloomOn.toggle() }
        }
        .padding(.horizontal, 16)
    }

    private func fxToggle(_ name: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(on ? Color.foticoPrimary : Color.white.opacity(0.15))
                .foregroundColor(on ? .black : .white)
                .cornerRadius(14)
        }
    }

    // Flash options
    private var flashOptions: some View {
        HStack(spacing: 16) {
            flashChip("Off", mode: .off)
            flashChip("On", mode: .on)
            flashChip("Auto", mode: .auto)
            flashChip("Vintage", mode: .vintage)
        }
        .padding(.horizontal, 16)
    }

    private func flashChip(_ name: String, mode: FlashMode) -> some View {
        Button {
            onFlashCycle()
            HapticManager.selection()
        } label: {
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(flashMode == mode ? Color.foticoPrimary : Color.white.opacity(0.15))
                .foregroundColor(flashMode == mode ? .black : .white)
                .cornerRadius(14)
        }
    }
}

// Supporting enums
enum GridMode: String, Sendable {
    case off, thirds, center, golden
}

enum GrainLevel: String, Sendable {
    case off, light, medium, heavy

    var intensity: Double {
        switch self {
        case .off: return 0
        case .light: return 0.02
        case .medium: return 0.04
        case .heavy: return 0.08
        }
    }
}
```

**Step 2: Commit**

```bash
git add Fotico/Views/Camera/CameraToolbarView.swift
git commit -m "feat: add CameraToolbarView with 5 tab panels"
```

---

### Task 9: Create GridOverlayView

**Files:**
- Create: `Fotico/Views/Camera/GridOverlayView.swift`

**Step 1: Create compositing grid overlay**

```swift
import SwiftUI

struct GridOverlayView: View {
    let mode: GridMode

    var body: some View {
        GeometryReader { geo in
            switch mode {
            case .off:
                EmptyView()
            case .thirds:
                thirdsGrid(in: geo.size)
            case .center:
                centerCross(in: geo.size)
            case .golden:
                goldenGrid(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func thirdsGrid(in size: CGSize) -> some View {
        ZStack {
            // Vertical lines
            ForEach([1, 2], id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 0.5)
                    .position(x: size.width * CGFloat(i) / 3, y: size.height / 2)
            }
            // Horizontal lines
            ForEach([1, 2], id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 0.5)
                    .position(x: size.width / 2, y: size.height * CGFloat(i) / 3)
            }
        }
    }

    private func centerCross(in size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 0.5, height: 20)
                .position(x: size.width / 2, y: size.height / 2)
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 20, height: 0.5)
                .position(x: size.width / 2, y: size.height / 2)
        }
    }

    private func goldenGrid(in size: CGSize) -> some View {
        let phi: CGFloat = 1.618
        let x1 = size.width / (1 + phi)
        let x2 = size.width - x1
        let y1 = size.height / (1 + phi)
        let y2 = size.height - y1

        return ZStack {
            ForEach([x1, x2], id: \.self) { x in
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 0.5)
                    .position(x: x, y: size.height / 2)
            }
            ForEach([y1, y2], id: \.self) { y in
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 0.5)
                    .position(x: size.width / 2, y: y)
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add Fotico/Views/Camera/GridOverlayView.swift
git commit -m "feat: add GridOverlayView for camera guide lines"
```

---

### Task 10: Overhaul CameraView UI

**Files:**
- Modify: `Fotico/Views/Camera/CameraView.swift`

**Step 1: Replace the entire CameraView layout**

Major changes:
1. Remove `CameraMode` toggle (modeToggle view)
2. Remove filter button + filter sheet
3. Add `CameraTypeStripView` above the capture button area
4. Add `CameraToolbarView` below the camera type strip
5. Add `GridOverlayView` on top of the live preview
6. Add new @State vars for toolbar state (`selectedTab`, `selectedFrame`, `gridMode`, `grainLevel`, `lightLeakOn`, `vignetteOn`, `bloomOn`)
7. Move flash toggle to toolbar (remove from top bar)
8. Keep: X close button, camera switch button, zoom controls, capture button

New layout from top to bottom:
```
┌─────────────────────────┐
│  X                    🔄 │  ← top bar (close + switch camera)
│                          │
│   Live Preview           │
│   + GridOverlayView      │
│                          │
│  0.5x  1x  2x  3x       │  ← zoom controls
│                          │
│ [DISP] [POLAR] [35mm]..  │  ← CameraTypeStripView
│                          │
│      ○ Capture ○         │  ← capture button centered
│                          │
│ Frame Grid Tex FX Flash  │  ← CameraToolbarView tabs
└─────────────────────────┘
```

**Step 2: Wire up toolbar state to CameraViewModel**

The toolbar state vars (grainLevel, lightLeakOn, etc.) override/supplement the camera type's defaults. The CameraViewModel needs to read these when processing frames.

**Step 3: Commit**

```bash
git add Fotico/Views/Camera/CameraView.swift
git commit -m "feat: overhaul CameraView with camera types strip and toolbar"
```

---

## Phase 4: Wire Camera Type Processing

### Task 11: Update CameraViewModel processing with toolbar state

**Files:**
- Modify: `Fotico/ViewModels/CameraViewModel.swift`

**Step 1: Add toolbar state properties**

Add published properties for toolbar overrides:

```swift
@Published var selectedFrame: String? = nil
@Published var gridMode: GridMode = .off
@Published var grainLevel: GrainLevel = .off
@Published var lightLeakOn: Bool = false
@Published var vignetteOn: Bool = false
@Published var bloomOn: Bool = false
@Published var selectedToolbarTab: CameraToolbarTab? = nil
```

**Step 2: Update processPreviewFrame to merge camera type + toolbar overrides**

The final grain/vignette/bloom/lightLeak values are: camera type default OR toolbar override (whichever is active). If the user manually toggles an effect ON via toolbar, it applies regardless of camera type. If the camera type has the effect and the user toggles it OFF, respect the toggle.

**Step 3: Update capturePhoto similarly**

Apply the same combined effects at full resolution during capture.

**Step 4: Commit**

```bash
git add Fotico/ViewModels/CameraViewModel.swift
git commit -m "feat: wire camera type + toolbar state into processing pipeline"
```

---

### Task 12: Add new files to Xcode project and build

**Files:**
- Modify: `Fotico.xcodeproj/project.pbxproj`

**Step 1: Add new Swift files to Xcode project**

New files to add:
- `Fotico/Models/CameraType.swift`
- `Fotico/Views/Camera/CameraTypeStripView.swift`
- `Fotico/Views/Camera/CameraToolbarView.swift`
- `Fotico/Views/Camera/GridOverlayView.swift`

**Step 2: Build and fix any compilation errors**

```bash
xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -30
```

**Step 3: Commit fixes**

```bash
git add -A
git commit -m "fix: resolve compilation errors from camera overhaul"
```
