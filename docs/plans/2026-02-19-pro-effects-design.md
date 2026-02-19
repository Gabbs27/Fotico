# Professional Editor Effects — Design Document

**Date:** 2026-02-19
**Status:** Approved

## Goal

Add 6 new professional-grade effects to the editor (post-capture) to give users cinematic, analog, and editorial looks. These complement the existing 8 effects (Grain, Light Leak, Bloom, Vignette, Solarize, Glitch, Fisheye, Threshold).

## New Effects

### 1. Dust (Polvo)
**Style:** Analog
**Technique:** Composite existing dust PNG overlays (`dust_01`, `dust_02`, `dust_03`) via `CISourceOverCompositing` with intensity-controlled alpha.
**Why separate from overlays?** Overlays require manual selection of a specific asset. This effect auto-applies a subtle dust texture with a single slider — faster, more discoverable, and always the right density.
**Parameters:** `dustIntensity` (0.0...1.0)

### 2. Halation (Halación)
**Style:** Analog/Film
**Technique:** Extract bright areas → `CIGaussianBlur` (radius ~30) → tint red/orange via `CIColorMatrix` → blend back with `CIScreenBlendMode`. Mimics film halation where bright areas bleed a red/orange glow onto adjacent areas.
**Parameters:** `halationIntensity` (0.0...1.0)

### 3. Chromatic Aberration (Aberración Cromática)
**Style:** Analog/Editorial
**Technique:** Separate R, G, B channels with `CIColorMatrix` → offset R and B with `CGAffineTransform` (opposite directions) → recompose with `CIAdditionCompositing`. Apply a radial falloff mask so center stays sharp, edges show the aberration.
**Parameters:** `chromaticAberrationIntensity` (0.0...1.0)

### 4. Film Burn (Quemadura)
**Style:** Analog
**Technique:** `CILinearGradient` with warm orange/red colors positioned in a corner → blend with `CIScreenBlendMode`. Simulates light burn from partially exposed film.
**Parameters:** `filmBurnIntensity` (0.0...1.0)

### 5. Soft Diffusion (Difusión)
**Style:** Editorial/Cinematic
**Technique:** Duplicate image → `CIGaussianBlur` → `CIHighlightShadowAdjust` to target highlights → blend with original via `CIScreenBlendMode` at reduced opacity. Mimics a Pro-Mist/Black Mist filter, making highlights glow softly without losing overall sharpness.
**Parameters:** `softDiffusionIntensity` (0.0...1.0)

### 6. Letterbox (Cinemascope)
**Style:** Cinematic
**Technique:** `CIConstantColorGenerator` (black) → crop to bar shapes → `CISourceOverCompositing` on top and bottom. Creates cinematic 2.39:1 aspect ratio bars. Intensity controls bar size from minimal to full cinematic ratio.
**Parameters:** `letterboxIntensity` (0.0...1.0)

## Architecture

### Files Modified

| File | Changes |
|------|---------|
| `Fotico/Models/EffectType.swift` | Add 6 new cases: `dust`, `halation`, `chromaticAberration`, `filmBurn`, `softDiffusion`, `letterbox` |
| `Fotico/Models/EditState.swift` | Add 6 new properties: `dustIntensity`, `halationIntensity`, `chromaticAberrationIntensity`, `filmBurnIntensity`, `softDiffusionIntensity`, `letterboxIntensity` |
| `Fotico/Services/ImageFilterService.swift` | Add 6 new `apply*` methods + wire into `applyEffects()` pipeline |
| `Fotico/Views/Editor/EffectsPanelView.swift` | No changes needed — iterates `EffectType.allCases` automatically |

### Pipeline Order in `applyEffects()`

Existing effects run first (vignette, bloom, solarize, light leak, glitch, fisheye, threshold, grain), then new effects in this order:

1. **Chromatic Aberration** — operates on raw pixel positions, before any blending
2. **Halation** — extracts highlights from current result, best before overlays
3. **Soft Diffusion** — highlight-targeted blur, after halation to avoid double-glow
4. **Film Burn** — additive gradient overlay
5. **Dust** — texture composite on top
6. **Letterbox** — always last, black bars overlay everything

### EffectType Mapping

Each effect maps to its EditState property via `switch` in `EffectsPanelView`:

```
.dust → editState.dustIntensity
.halation → editState.halationIntensity
.chromaticAberration → editState.chromaticAberrationIntensity
.filmBurn → editState.filmBurnIntensity
.softDiffusion → editState.softDiffusionIntensity
.letterbox → editState.letterboxIntensity
```

### Performance Considerations

- All effects use existing CIFilter primitives — no custom Metal kernels needed
- Halation and Soft Diffusion both use `CIGaussianBlur` which is the heaviest operation; at typical editor resolution this is well within budget
- Dust reuses existing overlay PNGs — no new assets needed
- Letterbox uses `CIConstantColorGenerator` which is nearly free
- Chromatic Aberration reuses the same channel-separation pattern as the existing Glitch effect

### Thread Safety

All new filter methods follow the existing pattern: create fresh `CIFilter` instances per call (not cached) for filters used infrequently, or use the cached instance pattern for frequently-called filters. Since `ImageFilterService` is documented as single-queue-only, this is safe.
