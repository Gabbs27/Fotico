# Camera Types + Editor Overhaul Design

**Date:** 2026-02-18
**Status:** Approved

## Goal

Overhaul Fotico into a two-experience app: (1) Camera with "camera types" as live preview (Disposable, Polaroid, 35mm, etc.) with a Tezza-style bottom toolbar, and (2) Editor with 5 featured filters (Soft, Golden, Clean, Vintage, Moody) + 27 existing LUT presets.

## Part 1: Camera — Camera Types with Live Preview

### Camera Types (horizontal strip, like Tezza)

Each camera type applies a LUT color grade + optional effects (grain, vignette, light leak) to the live preview. Icons are distinct camera silhouettes per type.

| Type | Look | LUT | Effects |
|------|------|-----|---------|
| Normal | No filter, clean photo | none | none |
| Disposable | Warm washed-out, cheap camera feel | disposable.cube | grain(0.3) + vignette(1.5) + light leak |
| Polaroid | Instant camera, soft vintage | polaroid.cube | slight vignette(0.8) |
| 35mm | Classic 35mm film | portra.cube | grain(0.15) |
| Fuji 400 | Fuji 400H film stock | fuji_400h.cube | grain(0.1) |
| Super8 | Cine Super8mm look | super8.cube | grain(0.4) + vignette(1.2) |
| Glow | Original Fotico: dreamy soft | honey.cube | bloom(0.3) |
| Nocturna | Night/flash shots, editorial | carbon.cube | vignette(0.6) |

### Camera UI Layout

**Top bar:**
- X (close) — left
- Flash toggle (off/on/auto/vintage) — center
- Camera switch (front/back) — right

**Center:**
- Full-screen live preview with selected camera type applied

**Bottom area:**
- Camera type strip (horizontal scroll, icons + names like Tezza)
- Bottom toolbar tabs:

| Tab | Icon | Function |
|-----|------|----------|
| Frame | `square` | Frame overlays: none, polaroid border, 35mm sprockets, super8 |
| Grid | `grid` | Guide overlays: none, rule of thirds, center cross, golden ratio |
| Texture | `line.3.horizontal` | Grain control: off, light, medium, heavy |
| FX | `fx` | Quick effects: light leak toggle, vignette toggle, bloom toggle |
| Flash | `bolt.fill` | Flash mode selection: off, on, auto, vintage |

**Capture button:** Centered below the camera type strip.

### Data Model: CameraType

New model separate from FilterPreset:

```swift
struct CameraType: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String          // SF Symbol or custom asset name
    let lutFileName: String?  // nil = Normal (no filter)
    let grainIntensity: Double
    let vignetteIntensity: Double
    let bloomIntensity: Double
    let lightLeakEnabled: Bool
}
```

Static list of 8 camera types defined inline. Camera types are NOT FilterPresets — they are a separate concept used only in camera mode.

### Camera Type Processing

Live preview: Apply LUT via LUTService + grain/vignette/bloom/light leak as CIFilter chain.
Capture: Same pipeline at full resolution.
The existing CameraFilters enum will be updated to use CameraType instead of FilterPreset.

## Part 2: Editor — 5 Featured Filters + 27 LUT Presets

### 5 Featured Filters (LUT-based, generated from Gemini specs)

These are generated as .cube LUT files with professional color grading that matches the Gemini specs:

| # | Name | Style | Key characteristics |
|---|------|-------|-------------------|
| 1 | Soft | Sweet & luminous | Low contrast, lifted shadows, slightly warm, softened texture |
| 2 | Golden | Golden hour vibes | High warmth, pink tint, illuminated skin, desaturated blues |
| 3 | Clean | Clean girl minimalist | Pure whites, near-desaturated, defined edges, sharp |
| 4 | Film | Vintage 90s film | Matte/washed blacks, warm, grain-ready contrast, boosted reds |
| 5 | Moody | Cinematic intense | Dark, high contrast, desaturated, vignette, dead greens |

### Editor Categories (updated)

| Category | Icon | Contents |
|----------|------|----------|
| Featured | `star.fill` | Soft, Golden, Clean, Film, Moody (the 5 new ones) |
| Clean Girl | `sparkles` | Cocoa, Butter, Goldie, Latte, Dorado, Canela, Glam |
| Soft | `cloud.fill` | Honey, Peach, Cloud, Blush, Petalo, Nube, Algodon, Brisa |
| Film | `film` | Portra, Fuji 400, Kodak, Polaroid, Super8, Carbon, Seda |
| Vintage | `clock.arrow.circlepath` | Disposable, Throwback, Nostalgia, VHS |

Total: 32 presets (5 featured + 27 existing LUTs)

### PresetCategory enum update

Add `featured` case as first case so it appears first in CaseIterable:

```swift
enum PresetCategory: String, CaseIterable, Sendable {
    case featured
    case cleanGirl
    case soft
    case film
    case vintage
}
```

## Part 3: What Stays the Same

- Editor manual adjustments (brightness, contrast, saturation, etc.)
- Editor effects panel (grain, bloom, vignette, light leak, etc.)
- Editor overlay panel (dust, light, paper, grain textures)
- Camera → Editor flow (capture routes to editor)
- No video support
- Project save/load system

## Implementation Phases

### Phase 1: Editor Featured Filters
- Generate 5 new LUT files (soft, golden, clean, film, moody)
- Add `featured` category to PresetCategory
- Add 5 new FilterPresets to allPresets
- Add LUTs to Xcode project

### Phase 2: Camera Types Model + Data
- Create CameraType model
- Define 8 camera types with LUT + effect params
- Update CameraViewModel to use CameraType instead of FilterPreset

### Phase 3: Camera UI Overhaul
- Replace current camera mode toggle (Normal/Film) with camera type strip
- Add bottom toolbar with tabs (Frame, Grid, Texture, FX, Flash)
- Update CameraView layout

### Phase 4: Camera Type Processing
- Update CameraFilters to process CameraType (LUT + effects)
- Apply grain/vignette/bloom/light leak based on CameraType config
- Apply on both live preview and capture

## Technical Notes

- 5 new LUTs generated with Python (same pipeline as existing LUTs)
- Camera types use existing LUT files — no new LUTs needed for camera
- CameraType is separate from FilterPreset to keep concerns clean
- Camera bottom toolbar tabs can reuse existing overlay/effect infrastructure
- Frame overlays already exist (polaroid, 35mm, super8) in Resources/Overlays
