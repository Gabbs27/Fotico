# Lumé v2: Tezza-Inspired Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform Lumé into a Tezza-style aesthetic photo editor with accounts, StoreKit 2 subscriptions, 40+ LUT presets, batch editing, texture overlays, and local project storage.

**Architecture:** Tab-based navigation (Editor, Camera, Projects, Profile). All data local via SwiftData. Auth via Sign in with Apple. Subscriptions via StoreKit 2. LUT presets via CIColorCubeWithColorSpace. Overlays via CISourceOverCompositing.

**Tech Stack:** SwiftUI, SwiftData, StoreKit 2, AuthenticationServices, CoreImage, Metal

**Base path:** `/Users/gabriel/East/Fotico/`

**Build command:** `cd /Users/gabriel/East && xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build 2>&1 | grep -E "(error:|warning:)" | head -30`

**CRITICAL build rules:**
- Default Actor Isolation = MainActor in build settings
- `import Combine` must be explicit where `.onReceive` or `AnyCancellable` is used
- Use `Color.foticoPrimary` (not `.foticoPrimary`) with Swift Charts
- Simulator: iPhone 17 Pro (not 16 Pro)

---

## Phase 1: Foundation — Models, SwiftData, Tab Navigation

### Task 1: Update EditState to be Codable

**Files:**
- Modify: `Models/EditState.swift`

**Step 1: Add Codable conformance to EditState and CropRect**

EditState needs to be serializable for project storage and batch editing clipboard.

```swift
import Foundation

struct EditState: Sendable, Equatable, Codable {
    var selectedPresetId: String?
    var presetIntensity: Double = 1.0

    // Basic adjustments
    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var saturation: Double = 1.0
    var exposure: Double = 0.0
    var sharpness: Double = 0.0
    var vibrance: Double = 0.0

    // Temperature & Tint
    var temperature: Double = 6500
    var tint: Double = 0.0

    // Effects
    var vignetteIntensity: Double = 0.0
    var vignetteRadius: Double = 1.0
    var grainIntensity: Double = 0.0
    var grainSize: Double = 0.5
    var bloomIntensity: Double = 0.0
    var bloomRadius: Double = 10.0
    var lightLeakIntensity: Double = 0.0
    var solarizeThreshold: Double = 0.0
    var glitchIntensity: Double = 0.0
    var fisheyeIntensity: Double = 0.0
    var thresholdLevel: Double = 0.0

    // Overlay
    var overlayId: String?
    var overlayIntensity: Double = 0.7

    // Crop
    var cropRect: CropRect?
    var rotation: Double = 0.0

    var isDefault: Bool {
        self == EditState()
    }

    mutating func reset() {
        self = EditState()
    }
}

struct CropRect: Sendable, Equatable, Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
```

**Step 2: Build and verify**

Run: build command
Expected: 0 errors

**Step 3: Commit**

```bash
git add Models/EditState.swift
git commit -m "feat: make EditState Codable, add overlay fields"
```

---

### Task 2: Expand FilterPreset model with tier and LUT support

**Files:**
- Modify: `Models/FilterPreset.swift`

**Step 1: Add PresetTier, expand FilterPreset, update PresetCategory**

Replace the entire file with the expanded model. FilterPreset gains `tier`, `lutFileName`, `sortOrder`. PresetCategory gets 4 new categories. FilterParameter becomes Codable.

```swift
import Foundation

enum PresetTier: String, Codable, Sendable {
    case free
    case pro
}

struct FilterPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: PresetCategory
    let tier: PresetTier
    let lutFileName: String?        // e.g. "kodak_gold.cube" — nil means CIFilter chain
    let ciFilterName: String?
    let parameters: [FilterParameter]
    let defaultIntensity: Double
    let sortOrder: Int

    // Convenience init for existing CIFilter-based presets
    init(id: String, name: String, displayName: String, category: PresetCategory,
         tier: PresetTier = .free, lutFileName: String? = nil,
         ciFilterName: String? = nil, parameters: [FilterParameter] = [],
         defaultIntensity: Double = 1.0, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category
        self.tier = tier
        self.lutFileName = lutFileName
        self.ciFilterName = ciFilterName
        self.parameters = parameters
        self.defaultIntensity = defaultIntensity
        self.sortOrder = sortOrder
    }
}
```

Keep all existing presets in `static let allPresets` but add `tier: .free` and `sortOrder:` to each. Then add ~30 new pro presets referencing LUT file names.

The full preset list with 40+ entries:

**Free presets (keep existing 18, add tier: .free):**
All current presets stay as-is with `tier: .free`.

**Pro LUT presets (~25 new):**
```swift
// -- Cálidos (warm) --
FilterPreset(id: "pro_dorado", name: "Dorado", displayName: "Dorado",
    category: .warm, tier: .pro, lutFileName: "dorado.cube", sortOrder: 100),
FilterPreset(id: "pro_miel", name: "Miel", displayName: "Miel",
    category: .warm, tier: .pro, lutFileName: "miel.cube", sortOrder: 101),
FilterPreset(id: "pro_canela", name: "Canela", displayName: "Canela",
    category: .warm, tier: .pro, lutFileName: "canela.cube", sortOrder: 102),
FilterPreset(id: "pro_atardecer", name: "Atardecer", displayName: "Atardecer",
    category: .warm, tier: .pro, lutFileName: "atardecer.cube", sortOrder: 103),

// -- Fríos (cool) --
FilterPreset(id: "pro_oceano", name: "Océano", displayName: "Océano",
    category: .cool, tier: .pro, lutFileName: "oceano.cube", sortOrder: 200),
FilterPreset(id: "pro_niebla", name: "Niebla", displayName: "Niebla",
    category: .cool, tier: .pro, lutFileName: "niebla.cube", sortOrder: 201),
FilterPreset(id: "pro_invierno", name: "Invierno", displayName: "Invierno",
    category: .cool, tier: .pro, lutFileName: "invierno.cube", sortOrder: 202),

// -- Cine --
FilterPreset(id: "pro_noche", name: "Noche", displayName: "Noche",
    category: .cinematic, tier: .pro, lutFileName: "noche.cube", sortOrder: 300),
FilterPreset(id: "pro_drama", name: "Drama", displayName: "Drama",
    category: .cinematic, tier: .pro, lutFileName: "drama.cube", sortOrder: 301),
FilterPreset(id: "pro_teal_orange", name: "Teal&Orange", displayName: "Teal&Orange",
    category: .cinematic, tier: .pro, lutFileName: "teal_orange.cube", sortOrder: 302),

// -- Suaves (soft/pastel) --
FilterPreset(id: "pro_petalo", name: "Pétalo", displayName: "Pétalo",
    category: .soft, tier: .pro, lutFileName: "petalo.cube", sortOrder: 400),
FilterPreset(id: "pro_nube", name: "Nube", displayName: "Nube",
    category: .soft, tier: .pro, lutFileName: "nube.cube", sortOrder: 401),
FilterPreset(id: "pro_algodon", name: "Algodón", displayName: "Algodón",
    category: .soft, tier: .pro, lutFileName: "algodon.cube", sortOrder: 402),
FilterPreset(id: "pro_brisa", name: "Brisa", displayName: "Brisa",
    category: .soft, tier: .pro, lutFileName: "brisa.cube", sortOrder: 403),

// -- Película (film) --
FilterPreset(id: "pro_kodak", name: "Kodak", displayName: "Kodak",
    category: .film, tier: .pro, lutFileName: "kodak_gold.cube", sortOrder: 500),
FilterPreset(id: "pro_fuji", name: "Fuji", displayName: "Fuji",
    category: .film, tier: .pro, lutFileName: "fuji_400h.cube", sortOrder: 501),
FilterPreset(id: "pro_polaroid", name: "Polaroid", displayName: "Polaroid",
    category: .film, tier: .pro, lutFileName: "polaroid.cube", sortOrder: 502),
FilterPreset(id: "pro_super8", name: "Super8", displayName: "Super8",
    category: .film, tier: .pro, lutFileName: "super8.cube", sortOrder: 503),

// -- Editorial --
FilterPreset(id: "pro_revista", name: "Revista", displayName: "Revista",
    category: .editorial, tier: .pro, lutFileName: "revista.cube", sortOrder: 600),
FilterPreset(id: "pro_portada", name: "Portada", displayName: "Portada",
    category: .editorial, tier: .pro, lutFileName: "portada.cube", sortOrder: 601),
FilterPreset(id: "pro_glam", name: "Glam", displayName: "Glam",
    category: .editorial, tier: .pro, lutFileName: "glam.cube", sortOrder: 602),
FilterPreset(id: "pro_mate", name: "Mate", displayName: "Mate",
    category: .editorial, tier: .pro, lutFileName: "mate.cube", sortOrder: 603),

// -- Vintage --
FilterPreset(id: "pro_nostalgia", name: "Nostalgia", displayName: "Nostalgia",
    category: .vintage, tier: .pro, lutFileName: "nostalgia.cube", sortOrder: 700),
FilterPreset(id: "pro_sepia", name: "Sepia", displayName: "Sepia",
    category: .vintage, tier: .pro, lutFileName: "sepia.cube", sortOrder: 701),
FilterPreset(id: "pro_disco", name: "Disco", displayName: "Disco",
    category: .vintage, tier: .pro, lutFileName: "disco.cube", sortOrder: 702),
FilterPreset(id: "pro_vhs", name: "VHS", displayName: "VHS",
    category: .vintage, tier: .pro, lutFileName: "vhs.cube", sortOrder: 703),

// -- B&W --
FilterPreset(id: "pro_carbon", name: "Carbón", displayName: "Carbón",
    category: .bw, tier: .pro, lutFileName: "carbon.cube", sortOrder: 800),
FilterPreset(id: "pro_seda", name: "Seda", displayName: "Seda",
    category: .bw, tier: .pro, lutFileName: "seda.cube", sortOrder: 801),
```

**Updated PresetCategory:**
```swift
enum PresetCategory: String, CaseIterable, Sendable {
    case film
    case warm
    case cool
    case bw
    case cinematic
    case soft
    case editorial
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .film: return "Película"
        case .warm: return "Cálidos"
        case .cool: return "Fríos"
        case .bw: return "B&W"
        case .cinematic: return "Cine"
        case .soft: return "Suaves"
        case .editorial: return "Editorial"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .film: return "film"
        case .warm: return "sun.max.fill"
        case .cool: return "snowflake"
        case .bw: return "circle.lefthalf.filled"
        case .cinematic: return "theatermasks"
        case .soft: return "cloud.fill"
        case .editorial: return "newspaper.fill"
        case .vintage: return "clock.arrow.circlepath"
        }
    }
}
```

**Step 2: Build and verify**

Run: build command — there will be errors where existing code references old FilterPreset init. Fix all call sites.

**Step 3: Commit**

```bash
git add Models/FilterPreset.swift
git commit -m "feat: expand FilterPreset with tier, LUT, 8 categories, 40+ presets"
```

---

### Task 3: Create SwiftData models

**Files:**
- Create: `Models/UserProfile.swift`
- Create: `Models/PhotoProject.swift`
- Create: `Models/SavedEdit.swift`
- Create: `Models/OverlayAsset.swift`

**Step 1: Create UserProfile model**

```swift
// Models/UserProfile.swift
import SwiftData
import Foundation

@Model
class UserProfile {
    var appleUserID: String?
    var displayName: String
    var email: String?
    var avatarData: Data?
    var createdAt: Date
    var subscriptionTier: String  // "free" or "pro" — SwiftData doesn't support enums directly

    init(displayName: String = "Usuario", email: String? = nil, appleUserID: String? = nil) {
        self.displayName = displayName
        self.email = email
        self.appleUserID = appleUserID
        self.createdAt = Date()
        self.subscriptionTier = "free"
    }

    var tier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTier) ?? .free }
        set { subscriptionTier = newValue.rawValue }
    }
}

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
}
```

**Step 2: Create PhotoProject model**

```swift
// Models/PhotoProject.swift
import SwiftData
import Foundation

@Model
class PhotoProject {
    var name: String
    var originalImagePath: String
    var editStateJSON: Data
    var thumbnailData: Data?
    var createdAt: Date
    var modifiedAt: Date

    init(name: String, originalImagePath: String, editState: EditState) {
        self.name = name
        self.originalImagePath = originalImagePath
        self.editStateJSON = (try? JSONEncoder().encode(editState)) ?? Data()
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    var editState: EditState? {
        try? JSONDecoder().decode(EditState.self, from: editStateJSON)
    }
}
```

**Step 3: Create SavedEdit model**

```swift
// Models/SavedEdit.swift
import SwiftData
import Foundation

@Model
class SavedEdit {
    var name: String
    var editStateJSON: Data
    var thumbnailData: Data?
    var createdAt: Date

    init(name: String, editState: EditState) {
        self.name = name
        self.editStateJSON = (try? JSONEncoder().encode(editState)) ?? Data()
        self.createdAt = Date()
    }

    var editState: EditState? {
        try? JSONDecoder().decode(EditState.self, from: editStateJSON)
    }
}
```

**Step 4: Create OverlayAsset model**

```swift
// Models/OverlayAsset.swift
import Foundation

struct OverlayAsset: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let category: OverlayCategory
    let fileName: String          // "dust_01.png"
    let tier: PresetTier
    let sortOrder: Int
}

enum OverlayCategory: String, CaseIterable, Sendable {
    case dust
    case light
    case frames
    case paper
    case grain

    var displayName: String {
        switch self {
        case .dust: return "Polvo"
        case .light: return "Luz"
        case .frames: return "Marcos"
        case .paper: return "Papel"
        case .grain: return "Grano"
        }
    }

    var icon: String {
        switch self {
        case .dust: return "sparkles"
        case .light: return "sun.max.fill"
        case .frames: return "rectangle.inset.filled"
        case .paper: return "doc.fill"
        case .grain: return "circle.dotted"
        }
    }
}
```

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add Models/UserProfile.swift Models/PhotoProject.swift Models/SavedEdit.swift Models/OverlayAsset.swift
git commit -m "feat: add SwiftData models for user, projects, saved edits, overlays"
```

---

### Task 4: Create HomeTabView and update FoticoApp

**Files:**
- Create: `Views/HomeTabView.swift`
- Modify: `App/FoticoApp.swift`

**Step 1: Create HomeTabView**

```swift
// Views/HomeTabView.swift
import SwiftUI

struct HomeTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MainEditorView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Editor")
                }
                .tag(0)

            CameraLaunchView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Cámara")
                }
                .tag(1)

            ProjectsGridView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Proyectos")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Perfil")
                }
                .tag(3)
        }
        .tint(Color.foticoPrimary)
    }
}
```

**Step 2: Create placeholder views** (to be implemented later)

```swift
// Views/Camera/CameraLaunchView.swift
import SwiftUI

struct CameraLaunchView: View {
    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color.foticoDark.ignoresSafeArea()
            if !showCamera {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.foticoPrimary)
                    Button("Abrir Cámara") {
                        showCamera = true
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { _ in showCamera = false }
        }
    }
}
```

```swift
// Views/Projects/ProjectsGridView.swift
import SwiftUI

struct ProjectsGridView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.foticoDark.ignoresSafeArea()
                Text("Proyectos")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Proyectos")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

```swift
// Views/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.foticoDark.ignoresSafeArea()
                Text("Perfil")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

**Step 3: Update FoticoApp to use SwiftData + HomeTabView**

```swift
// App/FoticoApp.swift
import SwiftUI
import SwiftData

@main
struct FoticoApp: App {
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [UserProfile.self, PhotoProject.self, SavedEdit.self])
    }
}
```

**Step 4: Build and verify**

**Step 5: Commit**

```bash
git add App/FoticoApp.swift Views/HomeTabView.swift Views/Camera/CameraLaunchView.swift Views/Projects/ProjectsGridView.swift Views/Profile/ProfileView.swift
git commit -m "feat: add tab navigation with HomeTabView, SwiftData container"
```

---

## Phase 2: LUT Preset System

### Task 5: Create LUTService (.cube file parser)

**Files:**
- Create: `Services/LUTService.swift`

**Step 1: Implement LUT parser + cache**

The `.cube` file format is:
```
LUT_3D_SIZE 64
0.0 0.0 0.0
0.0 0.0 0.015686
...
```

```swift
// Services/LUTService.swift
import CoreImage
import UIKit

/// Parses .cube LUT files and applies them via CIColorCubeWithColorSpace.
/// Caches parsed LUT data in memory to avoid re-parsing on every render.
/// Thread-safe: parsed data is immutable [Float] arrays.
final class LUTService: Sendable {
    static let shared = LUTService()

    // Cache of parsed LUT data: [fileName: (size, data)]
    private let cache = NSCache<NSString, LUTData>()

    private init() {
        cache.countLimit = 20  // Keep at most 20 LUTs in memory
    }

    /// Apply a .cube LUT to a CIImage. Returns original if LUT fails.
    func applyLUT(named fileName: String, to image: CIImage, intensity: Double = 1.0) -> CIImage {
        guard let lutData = loadLUT(named: fileName) else { return image }

        let filter = CIFilter(name: "CIColorCubeWithColorSpace")!
        filter.setValue(lutData.size, forKey: "inputCubeDimension")
        filter.setValue(lutData.data, forKey: "inputCubeData")
        filter.setValue(CGColorSpaceCreateDeviceRGB(), forKey: "inputColorSpace")
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let filtered = filter.outputImage else { return image }

        // Blend with original based on intensity
        if intensity < 1.0 {
            let blend = CIFilter(name: "CIDissolveTransition")!
            blend.setValue(image, forKey: kCIInputImageKey)
            blend.setValue(filtered, forKey: kCIInputTargetImageKey)
            blend.setValue(intensity, forKey: kCIInputTimeKey)
            return blend.outputImage ?? filtered
        }

        return filtered
    }

    /// Load and cache parsed LUT data from bundle
    private func loadLUT(named fileName: String) -> LUTData? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Try free/ then pro/ subdirectories
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube", subdirectory: "LUTs/free")
                ?? Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube", subdirectory: "LUTs/pro")
                ?? Bundle.main.url(forResource: nameWithoutExt, withExtension: "cube") else {
            print("[LUTService] LUT file not found: \(fileName)")
            return nil
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        guard let parsed = parseCubeFile(content) else { return nil }

        cache.setObject(parsed, forKey: key)
        return parsed
    }

    /// Parse .cube format into (dimension, float array as Data)
    private func parseCubeFile(_ content: String) -> LUTData? {
        var size = 0
        var values: [Float] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("TITLE") { continue }

            if trimmed.hasPrefix("LUT_3D_SIZE") {
                let parts = trimmed.split(separator: " ")
                if parts.count >= 2, let s = Int(parts[1]) {
                    size = s
                    values.reserveCapacity(size * size * size * 4)
                }
                continue
            }

            // Skip other metadata lines
            if trimmed.hasPrefix("DOMAIN_") { continue }

            let parts = trimmed.split(separator: " ")
            if parts.count >= 3,
               let r = Float(parts[0]),
               let g = Float(parts[1]),
               let b = Float(parts[2]) {
                values.append(r)
                values.append(g)
                values.append(b)
                values.append(1.0)  // Alpha
            }
        }

        guard size > 0, values.count == size * size * size * 4 else {
            print("[LUTService] Invalid LUT: expected \(size*size*size*4) values, got \(values.count)")
            return nil
        }

        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        return LUTData(size: size, data: data)
    }
}

/// Wrapper class for NSCache (requires reference type)
private final class LUTData: Sendable {
    let size: Int
    let data: Data

    init(size: Int, data: Data) {
        self.size = size
        self.data = data
    }
}
```

**Step 2: Build and verify**

**Step 3: Commit**

```bash
git add Services/LUTService.swift
git commit -m "feat: add LUTService with .cube file parser and memory cache"
```

---

### Task 6: Generate placeholder LUT .cube files

**Files:**
- Create: `Resources/LUTs/` directory structure with .cube files

Since we don't have real professional LUT files, we generate identity LUTs (pass-through) with slight color adjustments. Each file is a valid 17x17x17 3D LUT with a subtle color grade. Real LUT files can replace these later.

**Step 1: Create a Python script to generate LUTs**

Run a Python script that generates ~25 .cube files with distinct color grades:
- Warm presets: shift reds/oranges higher
- Cool presets: boost blues
- Film presets: crushed blacks, lifted shadows
- Etc.

Create directory structure:
```
Fotico/Resources/LUTs/dorado.cube
Fotico/Resources/LUTs/miel.cube
... (one per pro preset lutFileName)
```

**Step 2: Add the LUTs folder to the Xcode project bundle**

Add as a folder reference in project.pbxproj so they're bundled in the app.

**Step 3: Commit**

```bash
git add Resources/LUTs/ Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add generated .cube LUT files for 25 pro presets"
```

---

### Task 7: Integrate LUT support into ImageFilterService

**Files:**
- Modify: `Services/ImageFilterService.swift`

**Step 1: Add LUT application in applyPreset**

In `applyPreset(_:to:intensity:)`, check if preset has a `lutFileName`. If so, use `LUTService` instead of the CIFilter chain:

```swift
func applyPreset(_ preset: FilterPreset, to image: CIImage, intensity: Double) -> CIImage {
    var filtered: CIImage

    if let lutFileName = preset.lutFileName {
        // LUT-based preset (Pro)
        filtered = LUTService.shared.applyLUT(named: lutFileName, to: image, intensity: 1.0)
    } else if let ciFilterName = preset.ciFilterName {
        filtered = applyStandardPreset(ciFilterName, to: image)
    } else {
        filtered = applyCustomPreset(preset, to: image)
    }

    // Apply additional preset parameters
    filtered = applyPresetParameters(preset.parameters, to: filtered)

    // Blend with original based on intensity
    if intensity < 1.0 {
        filtered = blendImages(original: image, filtered: filtered, intensity: intensity)
    }

    return filtered
}
```

**Step 2: Build and verify**

**Step 3: Commit**

```bash
git add Services/ImageFilterService.swift
git commit -m "feat: integrate LUT support into filter pipeline"
```

---

### Task 8: Redesign PresetStripView with category tabs

**Files:**
- Modify: `Views/Editor/PresetStripView.swift`
- Create: `Views/Components/PremiumBadge.swift`

**Step 1: Create PremiumBadge component**

```swift
// Views/Components/PremiumBadge.swift
import SwiftUI

struct PremiumBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 10))
            .foregroundColor(.white)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .clipShape(Circle())
    }
}
```

**Step 2: Rewrite PresetStripView with category filter chips + lock badge**

```swift
// The new PresetStripView has:
// 1. Category chips at top (horizontal scroll)
// 2. "Todos" chip to show all
// 3. Preset thumbnails below with 🔒 overlay for pro presets
// 4. Intensity slider when preset selected
// 5. Tapping locked preset shows callback for paywall
```

The view accepts a new `isPro: Bool` binding and `onLockedPresetTapped: () -> Void`.

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add Views/Editor/PresetStripView.swift Views/Components/PremiumBadge.swift
git commit -m "feat: redesign PresetStripView with category tabs and premium badges"
```

---

## Phase 3: Overlays System

### Task 9: Create overlay PNG assets

**Files:**
- Create: `Resources/Overlays/` directory with PNG files

Generate or source overlay PNGs (1080x1080, transparent background):
- `dust_01.png` through `dust_03.png`
- `light_01.png` through `light_03.png`
- `frames_polaroid.png`, `frames_35mm.png`, `frames_super8.png`
- `paper_01.png`, `paper_02.png`
- `grain_fine.png`, `grain_heavy.png`

Add to Xcode project as folder reference.

**Commit:**
```bash
git add Resources/Overlays/ Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add overlay PNG assets (dust, light, frames, paper, grain)"
```

---

### Task 10: Create OverlayPanelView + integrate into editor

**Files:**
- Create: `Views/Editor/OverlayPanelView.swift`
- Modify: `ViewModels/PhotoEditorViewModel.swift` (add overlay support)
- Modify: `Services/ImageFilterService.swift` (add overlay compositing)
- Modify: `Views/MainEditorView.swift` (add overlay tool tab)
- Modify: `Views/Editor/ToolBarView.swift` (add overlay tab)

**Step 1: Add overlay tool to EditorTool enum**

In PhotoEditorViewModel.swift, update EditorTool:
```swift
enum EditorTool: String, CaseIterable, Sendable {
    case presets
    case adjust
    case effects
    case overlays
    case crop
    // ... update displayName and icon
}
```

**Step 2: Add overlay application to ImageFilterService**

After effects, before safety crop:
```swift
// 5.5 Apply overlay
if let overlayId = state.overlayId {
    image = applyOverlay(overlayId, to: image, intensity: state.overlayIntensity)
}
```

The overlay compositing method:
```swift
func applyOverlay(_ overlayId: String, to image: CIImage, intensity: Double) -> CIImage {
    let overlayAsset = OverlayAsset.allOverlays.first(where: { $0.id == overlayId })
    guard let asset = overlayAsset,
          let overlayUIImage = UIImage(named: asset.fileName),
          var overlayCIImage = CIImage(image: overlayUIImage) else { return image }

    let extent = image.extent

    // Scale overlay to match image size
    let scaleX = extent.width / overlayCIImage.extent.width
    let scaleY = extent.height / overlayCIImage.extent.height
    overlayCIImage = overlayCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

    // Adjust opacity
    if intensity < 1.0 {
        let alphaFilter = CIFilter(name: "CIColorMatrix")!
        alphaFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
        alphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
        overlayCIImage = alphaFilter.outputImage ?? overlayCIImage
    }

    // Composite over source
    let compositeFilter = CIFilter(name: "CISourceOverCompositing")!
    compositeFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
    compositeFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
    return compositeFilter.outputImage?.cropped(to: extent) ?? image
}
```

**Step 3: Create OverlayPanelView**

Grid layout similar to EffectsPanelView but showing overlay thumbnails grouped by category.

**Step 4: Wire into MainEditorView toolPanel switch**

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add Views/Editor/OverlayPanelView.swift Views/Editor/ToolBarView.swift Views/MainEditorView.swift ViewModels/PhotoEditorViewModel.swift Services/ImageFilterService.swift
git commit -m "feat: add overlay system with panel, compositing, and 5 tool tabs"
```

---

## Phase 4: Projects (Local Storage)

### Task 11: Create ProjectStorageService + ProjectsGridView

**Files:**
- Create: `Services/ProjectStorageService.swift`
- Modify: `Views/Projects/ProjectsGridView.swift`
- Create: `ViewModels/ProjectsViewModel.swift`

**Step 1: Create ProjectStorageService**

Uses Documents directory to store original images. SwiftData stores project metadata.

```swift
// Services/ProjectStorageService.swift
import UIKit

@MainActor
class ProjectStorageService {
    static let shared = ProjectStorageService()

    private let fileManager = FileManager.default

    private var projectsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("projects", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveOriginalImage(_ image: UIImage, projectId: String) -> String? {
        let fileName = "\(projectId).jpg"
        let path = projectsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        try? data.write(to: path)
        return fileName
    }

    func loadOriginalImage(fileName: String) -> UIImage? {
        let path = projectsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(fileName: String) {
        let path = projectsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: path)
    }
}
```

**Step 2: Build ProjectsViewModel**

**Step 3: Build ProjectsGridView with grid of thumbnails**

**Step 4: Add "save project" button to editor top toolbar**

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add Services/ProjectStorageService.swift ViewModels/ProjectsViewModel.swift Views/Projects/ProjectsGridView.swift ViewModels/PhotoEditorViewModel.swift Views/MainEditorView.swift
git commit -m "feat: add projects storage with grid view and save from editor"
```

---

## Phase 5: Accounts (Sign in with Apple)

### Task 12: Create AuthService + LoginView

**Files:**
- Create: `Services/AuthService.swift`
- Create: `ViewModels/AuthViewModel.swift`
- Create: `Views/Auth/LoginView.swift`
- Modify: `Views/Profile/ProfileView.swift`

**Step 1: Create AuthService**

Uses `AuthenticationServices` for Sign in with Apple. Stores credentials in Keychain.

**Step 2: Create AuthViewModel**

**Step 3: Create LoginView with Sign in with Apple button**

**Step 4: Update ProfileView with account info, login/logout**

**Step 5: Add Sign in with Apple capability to Xcode project**

**Step 6: Build and verify**

**Step 7: Commit**

```bash
git add Services/AuthService.swift ViewModels/AuthViewModel.swift Views/Auth/LoginView.swift Views/Profile/ProfileView.swift
git commit -m "feat: add Sign in with Apple auth with profile view"
```

---

## Phase 6: Subscriptions (StoreKit 2)

### Task 13: Create SubscriptionService + PaywallView

**Files:**
- Create: `Services/SubscriptionService.swift`
- Create: `ViewModels/SubscriptionViewModel.swift`
- Create: `Views/Auth/PaywallView.swift`
- Modify: `Views/Editor/PresetStripView.swift` (wire paywall)

**Step 1: Create SubscriptionService with StoreKit 2**

```swift
// Services/SubscriptionService.swift
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var products: [Product] = []
    @Published var isPro = false

    private let productIDs = ["com.lume.pro.monthly", "com.lume.pro.annual"]

    func loadProducts() async {
        do {
            products = try await Product.products(for: Set(productIDs))
        } catch {
            print("[Subscription] Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPro = true
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    isPro = true
                    return
                }
            }
        }
        isPro = false
    }

    func listenForUpdates() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await checkSubscriptionStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.unverified
        case .verified(let safe): return safe
        }
    }
}

enum SubscriptionError: Error {
    case unverified
}
```

**Step 2: Create PaywallView**

Beautiful paywall with feature comparison, price cards, restore button.

**Step 3: Wire paywall into PresetStripView**

When user taps a locked preset → present PaywallView as sheet.

**Step 4: Build and verify**

**Step 5: Commit**

```bash
git add Services/SubscriptionService.swift ViewModels/SubscriptionViewModel.swift Views/Auth/PaywallView.swift
git commit -m "feat: add StoreKit 2 subscriptions with paywall"
```

---

## Phase 7: Batch Editing (Copy/Paste)

### Task 14: Create EditClipboard + batch UI

**Files:**
- Create: `Services/EditClipboard.swift`
- Modify: `ViewModels/PhotoEditorViewModel.swift`
- Modify: `Views/MainEditorView.swift`

**Step 1: Create EditClipboard singleton**

```swift
// Services/EditClipboard.swift
import Foundation

@MainActor
class EditClipboard: ObservableObject {
    static let shared = EditClipboard()

    @Published var copiedState: EditState?

    var hasContent: Bool { copiedState != nil }

    func copy(_ state: EditState) {
        copiedState = state
    }

    func clear() {
        copiedState = nil
    }
}
```

**Step 2: Add copy/paste buttons to editor toolbar**

In top toolbar, after undo/redo:
- Copy button (doc.on.doc) — appears when edits are non-default
- Paste button (doc.on.clipboard) — appears when clipboard has content

**Step 3: Add paste functionality to PhotoEditorViewModel**

```swift
func pasteEdit() {
    guard let state = EditClipboard.shared.copiedState else { return }
    pushUndo()
    editState = state
    requestRender()
}

func copyEdit() {
    EditClipboard.shared.copy(editState)
    HapticManager.notification(.success)
}
```

**Step 4: Build and verify**

**Step 5: Commit**

```bash
git add Services/EditClipboard.swift ViewModels/PhotoEditorViewModel.swift Views/MainEditorView.swift
git commit -m "feat: add copy/paste edit clipboard for batch editing"
```

---

## Phase 8: Onboarding + Polish

### Task 15: Create OnboardingView

**Files:**
- Create: `Views/Onboarding/OnboardingView.swift`
- Modify: `Views/HomeTabView.swift`

**Step 1: Create OnboardingView**

3-page onboarding with:
1. Welcome — "LUME" logo + tagline
2. Features — presets, effects, camera
3. Get started — optional Sign in with Apple

Uses `@AppStorage("hasSeenOnboarding")` to show only on first launch.

**Step 2: Wire into HomeTabView**

```swift
@AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

var body: some View {
    if !hasSeenOnboarding {
        OnboardingView(onComplete: { hasSeenOnboarding = true })
    } else {
        // TabView...
    }
}
```

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add Views/Onboarding/OnboardingView.swift Views/HomeTabView.swift
git commit -m "feat: add 3-page onboarding with first-launch detection"
```

---

### Task 16: Final build verification + push

**Step 1: Full clean build**

```bash
cd /Users/gabriel/East && xcodebuild clean build -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E "error:" | head -20
```

Expected: 0 errors

**Step 2: Push all changes**

```bash
git push origin master
```

---

## Summary: 16 Tasks, 8 Phases

| Phase | Tasks | Key Deliverables |
|-------|-------|-----------------|
| 1. Foundation | 1-4 | Codable EditState, expanded FilterPreset, SwiftData models, tab nav |
| 2. LUT Presets | 5-8 | LUTService, .cube files, 40+ presets, category UI |
| 3. Overlays | 9-10 | PNG assets, overlay compositor, 5th tool tab |
| 4. Projects | 11 | Local storage, projects grid, save from editor |
| 5. Accounts | 12 | Sign in with Apple, profile view |
| 6. Subscriptions | 13 | StoreKit 2, paywall, premium gating |
| 7. Batch Edit | 14 | Copy/paste clipboard, toolbar buttons |
| 8. Polish | 15-16 | Onboarding, final verification |
