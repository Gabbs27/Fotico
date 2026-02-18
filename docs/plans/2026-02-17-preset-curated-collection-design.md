# Preset Curated Collection — Tezza/Dazz Inspired

**Date:** 2026-02-17
**Status:** Approved

## Goal

Replace 44 generic presets (8 categories) with a curated collection of ~26 presets in 4 trend-focused categories. Target audience: women who use Tezza, VSCO, and Dazz Cam. Clean Girl presets appear first.

## Categories (4, replacing 8)

| Category | Key | Icon | Description |
|----------|-----|------|-------------|
| Clean Girl | `cleanGirl` | `sparkles` | Luminous warm tones, skin-flattering, golden hour |
| Soft | `soft` | `cloud.fill` | Pastels, low contrast, dreamy, airy |
| Film | `film` | `film` | Analog film emulation, grain, Kodak/Fuji |
| Vintage | `vintage` | `clock.arrow.circlepath` | Retro, faded, warm nostalgia, disposable camera |

## Presets Removed (28)

E1, E2, E3, E4, E5, Sunset, Cool, Vivid, Neon, Golden, Soft (CIFilter), BW, Noir, Tonal, Silver, Cine, Retro, Faded, Océano, Niebla, Invierno, Noche, Drama, Teal&Orange, Atardecer, Revista, Portada, Mate, Disco, Sepia.

## LUT Files Removed (14)

oceano.cube, niebla.cube, invierno.cube, noche.cube, drama.cube, teal_orange.cube, revista.cube, portada.cube, mate.cube, atardecer.cube, disco.cube, sepia.cube, dorado.cube (replaced by Goldie CIFilter), miel.cube (replaced by Honey Gold CIFilter).

**Wait — keep dorado.cube and miel.cube** since they are LUT-based and sound better as LUTs. Actually: Dorado and Canela stay as LUT presets (reclassified to Clean Girl). Miel is renamed to "Honey Gold" but keeps its LUT.

## LUT Files Removed (12)

oceano.cube, niebla.cube, invierno.cube, noche.cube, drama.cube, teal_orange.cube, revista.cube, portada.cube, mate.cube, atardecer.cube, disco.cube, sepia.cube.

## New Presets (10 CIFilter-based + 1 LUT)

### Clean Girl (new)
- **Cocoa**: temp(7800) + sat(0.95) + contrast(1.05) + brightness(0.03) — chocolate warm tones
- **Butter**: temp(7500) + sat(1.1) + contrast(0.9) + brightness(0.05) — creamy yellow
- **Goldie**: temp(8200) + sat(1.05) + contrast(1.1) + vignette(0.5) — golden hour
- **Latte**: temp(7200) + sat(0.8) + contrast(0.95) + brightness(0.04) — beige/nude matte

### Soft (new)
- **Honey**: temp(7600) + sat(0.85) + contrast(0.85) + brightness(0.06) — luminous honey
- **Peach**: temp(7000) + sat(0.9) + contrast(0.88) + brightness(0.05) — pastel peach
- **Cloud**: contrast(0.78) + sat(0.85) + brightness(0.07) + temp(6800) — ultra dreamy
- **Blush**: temp(6500) + sat(1.05) + contrast(0.85) + brightness(0.04) — soft pink

### Film (new)
- **Portra**: New LUT portra.cube — Kodak Portra warm skin tones

### Vintage (new)
- **Disposable**: temp(8000) + sat(0.7) + contrast(1.15) + grain(0.35) + vignette(1.5)
- **Throwback**: temp(7800) + sat(0.55) + contrast(0.9) + brightness(0.05) + grain(0.2)

## Existing Presets Kept (reclassified)

### Clean Girl
- Dorado (LUT, from warm) — sortOrder 5
- Canela (LUT, from warm) — sortOrder 6
- Glam (LUT, from editorial) — sortOrder 7

### Soft
- Pétalo (LUT) — sortOrder 5
- Nube (LUT) — sortOrder 6
- Algodón (LUT) — sortOrder 7
- Brisa (LUT) — sortOrder 8

### Film
- Kodak (LUT) — sortOrder 2
- Fuji → renamed "Fuji 400" (LUT) — sortOrder 3
- Polaroid (LUT) — sortOrder 4
- Super8 (LUT) — sortOrder 5
- Carbón (LUT, from B&W) — sortOrder 6
- Seda (LUT, from B&W) — sortOrder 7

### Vintage
- Nostalgia (LUT) — sortOrder 3
- VHS (LUT) — sortOrder 4

## Final Preset Order

### 1. Clean Girl (7 presets)
1. Cocoa (new, CIFilter)
2. Butter (new, CIFilter)
3. Goldie (new, CIFilter)
4. Latte (new, CIFilter)
5. Dorado (existing LUT)
6. Canela (existing LUT)
7. Glam (existing LUT)

### 2. Soft (8 presets)
1. Honey (new, CIFilter)
2. Peach (new, CIFilter)
3. Cloud (new, CIFilter)
4. Blush (new, CIFilter)
5. Pétalo (existing LUT)
6. Nube (existing LUT)
7. Algodón (existing LUT)
8. Brisa (existing LUT)

### 3. Film (8 presets)
1. Portra (new LUT)
2. Fuji 400 (existing LUT, renamed)
3. Kodak (existing LUT)
4. Polaroid (existing LUT)
5. Super8 (existing LUT)
6. Carbón (existing LUT, from B&W)
7. Seda (existing LUT, from B&W)

### 4. Vintage (4 presets)
1. Disposable (new, CIFilter)
2. Throwback (new, CIFilter)
3. Nostalgia (existing LUT)
4. VHS (existing LUT)

**Total: 27 presets across 4 categories**

## Technical Notes

- New CIFilter presets use existing parameter infrastructure (temperature, saturation, contrast, brightness, vignette, grain)
- Portra LUT needs to be generated/sourced as a .cube file
- Categories enum changes from 8 to 4 cases — update PresetCategory and PresetGridView
- Remove unused LUT .cube files from bundle to reduce app size
- Miel renamed to "Honey Gold" — actually, let's just remove Miel and use Honey (CIFilter) instead. Simpler.
