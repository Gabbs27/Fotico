# Soft Focus Collection — 6 Editorial Presets

## Context

Inspired by the Labbet app aesthetic — film-inspired, "beautifully imperfect" editorial looks with pronounced grain, vignette, soft diffusion, and muted/selective colors. This is a trending look on social media for portrait and fashion photography.

## Architecture

**Approach:** LUT + Parameters (consistent with all existing presets)
- 6 new `.cube` LUT files for color transformations
- Parameters leverage existing effects: grain, vignette, softDiffusion, bloom
- New `softFocus` case in `PresetCategory` enum

**No changes needed to:** ImageFilterService, MetalKernelService, RenderEngine, EditState, or any effect processing code.

## New Category

- **Enum case:** `softFocus`
- **Display name:** "Soft Focus"
- **Icon:** `camera.filters`
- **Position:** After `vintage` in `PresetCategory`
- **Tier:** All free

## 6 Presets

### 1. Muse (`sf_muse`)
- **Mood:** Warm editorial (matches the reference photo — desaturated warm tones, skin-friendly)
- **LUT:** Desaturated warm, lifted blacks, reduced contrast, skin tones preserved
- **Params:** grain=0.55, vignette=0.50, softDiffusion=0.40, bloom=0.15

### 2. Haze (`sf_haze`)
- **Mood:** Dreamy fog/neblina
- **LUT:** Heavy fade, highlights pushed up, cool-warm midtones
- **Params:** grain=0.40, vignette=0.35, softDiffusion=0.55, bloom=0.25

### 3. Matte (`sf_matte`)
- **Mood:** Flat magazine editorial
- **LUT:** Lifted blacks (matte look), low contrast, slightly desaturated, neutral tones
- **Params:** grain=0.50, vignette=0.40, softDiffusion=0.30, bloom=0.10

### 4. Dusk (`sf_dusk`)
- **Mood:** Cool twilight editorial
- **LUT:** Blue/violet shadows, cool highlights, reduced warmth
- **Params:** grain=0.45, vignette=0.45, softDiffusion=0.35, bloom=0.20

### 5. Ivory (`sf_ivory`)
- **Mood:** Bright & airy but soft
- **LUT:** Creamy highlights, heavy fade, warm whites, low saturation
- **Params:** grain=0.35, vignette=0.30, softDiffusion=0.45, bloom=0.30

### 6. Noir (`sf_noir`)
- **Mood:** B&W editorial with character
- **LUT:** Monochrome conversion, lifted blacks, medium contrast, slight warmth in shadows
- **Params:** grain=0.60, vignette=0.55, softDiffusion=0.25, bloom=0.10

## LUT Generation

Python script to generate 6 identity-based 33x33x33 `.cube` files with color transformations:
- Each LUT starts from identity and applies specific color grading curves
- Common traits: lifted blacks, reduced saturation, characteristic tone curve
- Output to `Fotico/Resources/LUTs/free/`

## Files to Modify

1. `Fotico/Models/FilterPreset.swift` — Add `softFocus` category + 6 preset definitions
2. `Fotico/Resources/LUTs/free/` — 6 new `.cube` files

## Files That Update Automatically

- `CategoryChipView.swift` — Iterates `PresetCategory.allCases`
- `PresetGridView.swift` — Filters by category
- Thumbnail generation uses existing `ImageFilterService.generateThumbnail()`
