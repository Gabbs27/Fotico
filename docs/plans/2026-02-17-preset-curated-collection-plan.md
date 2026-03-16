# Curated Preset Collection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace 44 generic presets (8 categories) with 27 curated presets in 4 trend-focused categories (Clean Girl, Soft, Film, Vintage), targeting Tezza/Dazz aesthetic.

**Architecture:** Modify `FilterPreset.swift` to define new categories and presets. Update `PresetGridView.swift` category chips. Clean up `ImageFilterService.swift` and `CameraViewModel.swift` by removing dead custom preset code (fotico_cine, fotico_retro). Generate one new LUT file (portra.cube). Remove 12 unused .cube files from bundle.

**Tech Stack:** Swift, SwiftUI, CoreImage (CIFilter chains), LUT .cube files

---

### Task 1: Update PresetCategory enum (4 categories replacing 8)

**Files:**
- Modify: `Fotico/Models/FilterPreset.swift:285-320`

**Step 1: Replace the PresetCategory enum**

Replace the entire `PresetCategory` enum with:

```swift
enum PresetCategory: String, CaseIterable, Sendable {
    case cleanGirl
    case soft
    case film
    case vintage

    nonisolated var displayName: String {
        switch self {
        case .cleanGirl: return "Clean Girl"
        case .soft: return "Soft"
        case .film: return "Film"
        case .vintage: return "Vintage"
        }
    }

    nonisolated var icon: String {
        switch self {
        case .cleanGirl: return "sparkles"
        case .soft: return "cloud.fill"
        case .film: return "film"
        case .vintage: return "clock.arrow.circlepath"
        }
    }
}
```

**Step 2: Commit**

```bash
git add Fotico/Models/FilterPreset.swift
git commit -m "refactor: replace 8 preset categories with 4 trend-focused ones"
```

---

### Task 2: Replace all presets with curated collection

**Files:**
- Modify: `Fotico/Models/FilterPreset.swift:37-280`

**Step 1: Replace freePresets and proPresets**

Replace everything from line 37 (`// MARK: - All Presets`) through line 280 (end of `proPresets`) with the new preset definitions. Keep `allPresets` as `freePresets + proPresets`.

New `freePresets` (10 new CIFilter-based presets):

```swift
static let freePresets: [FilterPreset] = [
    // MARK: Clean Girl
    FilterPreset(
        id: "cocoa", name: "Cocoa", displayName: "Cocoa",
        category: .cleanGirl, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7800, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.95, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 1.05, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.03, minValue: -1, maxValue: 1),
        ],
        sortOrder: 0
    ),
    FilterPreset(
        id: "butter", name: "Butter", displayName: "Butter",
        category: .cleanGirl, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7500, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 1.1, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.9, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
        ],
        sortOrder: 1
    ),
    FilterPreset(
        id: "goldie", name: "Goldie", displayName: "Goldie",
        category: .cleanGirl, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 8200, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 1.05, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 1.1, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "vignette", value: 0.5, minValue: 0, maxValue: 3),
        ],
        sortOrder: 2
    ),
    FilterPreset(
        id: "latte", name: "Latte", displayName: "Latte",
        category: .cleanGirl, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7200, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.8, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.95, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1),
        ],
        sortOrder: 3
    ),

    // MARK: Soft
    FilterPreset(
        id: "honey", name: "Honey", displayName: "Honey",
        category: .soft, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7600, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.06, minValue: -1, maxValue: 1),
        ],
        sortOrder: 100
    ),
    FilterPreset(
        id: "peach", name: "Peach", displayName: "Peach",
        category: .soft, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7000, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.9, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.88, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
        ],
        sortOrder: 101
    ),
    FilterPreset(
        id: "cloud", name: "Cloud", displayName: "Cloud",
        category: .soft, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 6800, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.85, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.78, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.07, minValue: -1, maxValue: 1),
        ],
        sortOrder: 102
    ),
    FilterPreset(
        id: "blush", name: "Blush", displayName: "Blush",
        category: .soft, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 6500, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 1.05, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.85, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.04, minValue: -1, maxValue: 1),
        ],
        sortOrder: 103
    ),

    // MARK: Vintage
    FilterPreset(
        id: "disposable", name: "Disposable", displayName: "Disposable",
        category: .vintage, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 8000, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.7, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 1.15, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "grain", value: 0.35, minValue: 0, maxValue: 1),
            FilterParameter(key: "vignette", value: 1.5, minValue: 0, maxValue: 3),
        ],
        sortOrder: 300
    ),
    FilterPreset(
        id: "throwback", name: "Throwback", displayName: "Throwback",
        category: .vintage, tier: .free,
        parameters: [
            FilterParameter(key: "temperature", value: 7800, minValue: 2000, maxValue: 10000),
            FilterParameter(key: "saturation", value: 0.55, minValue: 0, maxValue: 2),
            FilterParameter(key: "contrast", value: 0.9, minValue: 0.25, maxValue: 4),
            FilterParameter(key: "brightness", value: 0.05, minValue: -1, maxValue: 1),
            FilterParameter(key: "grain", value: 0.2, minValue: 0, maxValue: 1),
        ],
        sortOrder: 301
    ),
]
```

New `proPresets` (17 LUT-based presets, reclassified):

```swift
static let proPresets: [FilterPreset] = [
    // MARK: Clean Girl (LUT)
    FilterPreset(id: "pro_dorado", name: "Dorado", displayName: "Dorado",
                 category: .cleanGirl, tier: .free, lutFileName: "dorado.cube", sortOrder: 4),
    FilterPreset(id: "pro_canela", name: "Canela", displayName: "Canela",
                 category: .cleanGirl, tier: .free, lutFileName: "canela.cube", sortOrder: 5),
    FilterPreset(id: "pro_glam", name: "Glam", displayName: "Glam",
                 category: .cleanGirl, tier: .free, lutFileName: "glam.cube", sortOrder: 6),

    // MARK: Soft (LUT)
    FilterPreset(id: "pro_petalo", name: "Pétalo", displayName: "Pétalo",
                 category: .soft, tier: .free, lutFileName: "petalo.cube", sortOrder: 104),
    FilterPreset(id: "pro_nube", name: "Nube", displayName: "Nube",
                 category: .soft, tier: .free, lutFileName: "nube.cube", sortOrder: 105),
    FilterPreset(id: "pro_algodon", name: "Algodón", displayName: "Algodón",
                 category: .soft, tier: .free, lutFileName: "algodon.cube", sortOrder: 106),
    FilterPreset(id: "pro_brisa", name: "Brisa", displayName: "Brisa",
                 category: .soft, tier: .free, lutFileName: "brisa.cube", sortOrder: 107),

    // MARK: Film (LUT)
    FilterPreset(id: "pro_portra", name: "Portra", displayName: "Portra",
                 category: .film, tier: .free, lutFileName: "portra.cube", sortOrder: 200),
    FilterPreset(id: "pro_fuji", name: "Fuji 400", displayName: "Fuji 400",
                 category: .film, tier: .free, lutFileName: "fuji_400h.cube", sortOrder: 201),
    FilterPreset(id: "pro_kodak", name: "Kodak", displayName: "Kodak",
                 category: .film, tier: .free, lutFileName: "kodak_gold.cube", sortOrder: 202),
    FilterPreset(id: "pro_polaroid", name: "Polaroid", displayName: "Polaroid",
                 category: .film, tier: .free, lutFileName: "polaroid.cube", sortOrder: 203),
    FilterPreset(id: "pro_super8", name: "Super8", displayName: "Super8",
                 category: .film, tier: .free, lutFileName: "super8.cube", sortOrder: 204),
    FilterPreset(id: "pro_carbon", name: "Carbón", displayName: "Carbón",
                 category: .film, tier: .free, lutFileName: "carbon.cube", sortOrder: 205),
    FilterPreset(id: "pro_seda", name: "Seda", displayName: "Seda",
                 category: .film, tier: .free, lutFileName: "seda.cube", sortOrder: 206),

    // MARK: Vintage (LUT)
    FilterPreset(id: "pro_nostalgia", name: "Nostalgia", displayName: "Nostalgia",
                 category: .vintage, tier: .free, lutFileName: "nostalgia.cube", sortOrder: 302),
    FilterPreset(id: "pro_vhs", name: "VHS", displayName: "VHS",
                 category: .vintage, tier: .free, lutFileName: "vhs.cube", sortOrder: 303),
]
```

**Step 2: Commit**

```bash
git add Fotico/Models/FilterPreset.swift
git commit -m "feat: replace 44 presets with 27 curated Tezza-style collection"
```

---

### Task 3: Remove dead custom preset code

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift:136-181`
- Modify: `Fotico/ViewModels/CameraViewModel.swift:211-227`

**Step 1: Simplify applyCustomPreset in ImageFilterService**

The presets `fotico_cine` and `fotico_retro` no longer exist. Replace the `applyCustomPreset` method (lines 136-145) and remove `applyCinematicGrade` (147-159) and `applyRetroLook` (162-181):

```swift
private func applyCustomPreset(_ preset: FilterPreset, to image: CIImage) -> CIImage {
    // All custom presets removed — parameter-only presets handled by applyPresetParameters
    return image
}
```

Delete `applyCinematicGrade` and `applyRetroLook` methods entirely.

**Step 2: Simplify CameraFilters in CameraViewModel**

Replace the custom preset switch (lines 211-227) with:

```swift
        // No custom presets — parameter-only presets handled by editor pipeline
        default:
            return image
```

**Step 3: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift Fotico/ViewModels/CameraViewModel.swift
git commit -m "refactor: remove dead custom preset code (cine, retro)"
```

---

### Task 4: Generate Portra LUT file

**Files:**
- Create: `Fotico/Resources/LUTs/portra.cube`

**Step 1: Generate a Kodak Portra-style LUT**

Create a Python script to generate a 33x33x33 .cube LUT that emulates Kodak Portra 400 characteristics:
- Warm skin tones (slight orange shift in midtones)
- Slightly desaturated shadows
- Gentle highlight rolloff
- Warm color cast overall

```python
#!/usr/bin/env python3
"""Generate a Kodak Portra 400-style LUT (.cube format)"""

SIZE = 33

def clamp(v):
    return max(0.0, min(1.0, v))

def portra_transform(r, g, b):
    # Warm shift: boost reds slightly, reduce blues
    r2 = clamp(r * 1.05 + 0.02)
    g2 = clamp(g * 1.02 + 0.01)
    b2 = clamp(b * 0.92 - 0.01)

    # Desaturate shadows (low luminance)
    lum = 0.299 * r2 + 0.587 * g2 + 0.114 * b2
    shadow_desat = max(0.0, 1.0 - lum * 2.5)  # stronger in deep shadows
    desat_amount = shadow_desat * 0.3
    r2 = clamp(r2 + (lum - r2) * desat_amount)
    g2 = clamp(g2 + (lum - g2) * desat_amount)
    b2 = clamp(b2 + (lum - b2) * desat_amount)

    # Gentle S-curve for contrast
    def soft_s(x):
        return clamp(x + 0.08 * (x - 0.5) * (1.0 - abs(x - 0.5) * 2))

    r2 = soft_s(r2)
    g2 = soft_s(g2)
    b2 = soft_s(b2)

    # Highlight rolloff (compress highlights gently)
    def highlight_roll(x):
        if x > 0.75:
            excess = x - 0.75
            return clamp(0.75 + excess * 0.85)
        return x

    r2 = highlight_roll(r2)
    g2 = highlight_roll(g2)
    b2 = highlight_roll(b2)

    return r2, g2, b2

with open("portra.cube", "w") as f:
    f.write(f"TITLE \"Portra 400\"\n")
    f.write(f"LUT_3D_SIZE {SIZE}\n\n")
    for b_i in range(SIZE):
        for g_i in range(SIZE):
            for r_i in range(SIZE):
                r = r_i / (SIZE - 1)
                g = g_i / (SIZE - 1)
                b = b_i / (SIZE - 1)
                r2, g2, b2 = portra_transform(r, g, b)
                f.write(f"{r2:.6f} {g2:.6f} {b2:.6f}\n")
```

Run this script, then copy the output to `Fotico/Resources/LUTs/portra.cube`.

**Step 2: Commit**

```bash
git add Fotico/Resources/LUTs/portra.cube
git commit -m "feat: add Portra 400-style LUT file"
```

---

### Task 5: Remove unused LUT files from bundle

**Files:**
- Delete 12 files from `Fotico/Resources/LUTs/`:
  - `oceano.cube`
  - `niebla.cube`
  - `invierno.cube`
  - `noche.cube`
  - `drama.cube`
  - `teal_orange.cube`
  - `revista.cube`
  - `portada.cube`
  - `mate.cube`
  - `atardecer.cube`
  - `disco.cube`
  - `sepia.cube`
  - `miel.cube`

**Step 1: Delete unused LUT files**

```bash
cd Fotico/Resources/LUTs/
rm oceano.cube niebla.cube invierno.cube noche.cube drama.cube teal_orange.cube revista.cube portada.cube mate.cube atardecer.cube disco.cube sepia.cube miel.cube
```

**Step 2: Also remove them from the Xcode project if they're listed in the pbxproj** — search the project file for references to these filenames and remove any build phase entries.

**Step 3: Commit**

```bash
git add -A Fotico/Resources/LUTs/
git commit -m "chore: remove 13 unused LUT files from bundle"
```

---

### Task 6: Build and verify

**Step 1: Build the project**

```bash
xcodebuild -project Fotico.xcodeproj -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED

**Step 2: Fix any compilation errors** (likely from removed category references)

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve compilation errors from preset refactor"
```
