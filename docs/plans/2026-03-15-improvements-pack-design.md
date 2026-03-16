# Lumé Improvements Pack — Design Document

**Date:** 2026-03-15
**Status:** Approved

## Overview

12 improvements to the Lumé photo editor, ranging from quick wins to major features. Grouped by complexity.

---

## 1. Motion Blur Mask In/Out Toggle

Replace "Clear Mask" with In/Out segmented control:
- **In** (default): blur applies inside painted area
- **Out**: blur applies outside painted area (inverts mask via `CIColorInvert`)
- Small trash icon button retained for clearing mask

**Files:** `EditState.swift`, `ImageFilterService.swift`, `EffectsPanelView.swift`

## 2. Before/After Preview

Slider-based comparison overlay:
- Eye button in toolbar (visible when edits exist)
- Vertical divider: Original (left) | Edited (right)
- DragGesture to slide divider
- Tap outside or X to close

**Files:** New `BeforeAfterView.swift`, `MainEditorView.swift`, `ToolBarView.swift`

## 3. Highlights & Shadows

Two new adjustment sliders:
- Highlights (-1.0 to 1.0) via `CIHighlightShadowAdjust` inputHighlightAmount
- Shadows (-1.0 to 1.0) via `CIHighlightShadowAdjust` inputShadowAmount

**Files:** `EditState.swift`, `ImageFilterService.swift`, `AdjustmentPanelView.swift`

## 4. Clarity Slider

Microcontrast/local contrast adjustment:
- Range: 0.0 to 2.0
- Implementation: `CIUnsharpMask` with large radius (10-20px)

**Files:** `EditState.swift`, `ImageFilterService.swift`, `AdjustmentPanelView.swift`

## 5. Low-Res Effect

Vintage digital camera imperfection:
- New `EffectType.lowRes` in `.stylize` category
- Pipeline: `CIPixellate` → `CIPosterize` for color banding
- Intensity controls pixelation size and posterize levels

**Files:** `EffectType.swift`, `EditState.swift`, `ImageFilterService.swift`

## 6. Film Blur

Cinematic atmospheric softness (distinct from Motion Blur):
- New `EffectType.filmBlur` in `.blur` category
- `CIGaussianBlur` with small radius (2-8px) blended with original
- Omnidirectional, subtle, dreamy

**Files:** `EffectType.swift`, `EditState.swift`, `ImageFilterService.swift`

## 7. Favorite Presets

Star/heart toggle on presets:
- `@AppStorage("favoritePresets")` with `Set<String>` of preset IDs
- "★ Favorites" section at top of PresetGridView when favorites exist
- Long press or heart button to toggle

**Files:** `PresetGridView.swift`

## 8. Aspect Ratio Presets in Crop

Horizontal chips in CropView:
- Free, 1:1, 4:5, 9:16, 16:9, 4:3
- Adjusts cropRect proportionally when selected
- New `CropAspectRatio` enum

**Files:** `EditState.swift`, `CropView.swift`

## 9. Edges/Borders

Darkroom-style borders:
- New overlay category `OverlayCategory.edges`
- 4-6 PNG border assets (Polaroid, 35mm, torn, minimal inset)
- Applied with `.normal` blend mode (not screen)
- Reuses existing OverlayAsset infrastructure

**Files:** `OverlayAsset.swift`, `OverlayPanelView.swift`, `ImageFilterService.swift`, border PNG assets

## 10. Color Tone (Split Toning)

Professional color grading with separate shadow/highlight tints:
- 4 properties: shadowToneHue, shadowToneSaturation, highlightToneHue, highlightToneSaturation
- Color circle pickers for shadows and highlights
- New tool section or advanced adjustments panel

**Files:** `EditState.swift`, `ImageFilterService.swift`, new `ColorTonePanelView.swift`

## 11. HSL Panel

Per-color Hue/Saturation/Luminance control:
- 8 color ranges: Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta
- 3 sliders per range (H/S/L) = 24 properties
- Custom Metal shader for selective HSL (performance)
- UI: color selector chips + 3 sliders

**Files:** `EditState.swift`, new `HSLShader.metal`, `MetalKernelService.swift`, `ImageFilterService.swift`, new `HSLPanelView.swift`

## 12. Labbet Link (Shareable Edits)

Share edit recipes as links:
- Serialize EditState → JSON → Base64 → URL: `lume://edit?data=...`
- Share via UIActivityViewController
- Deep link handler to import and apply edit state

**Files:** New `EditShareService.swift`, `PhotoEditorViewModel.swift`, URL scheme in Info.plist
