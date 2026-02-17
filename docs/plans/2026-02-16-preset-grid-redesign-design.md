# Preset Grid Redesign — Design Doc

## Problem

With 60+ presets, the horizontal scroll strip is unusable in both the editor and camera. Finding a specific filter requires scrolling through dozens of tiny thumbnails or text chips.

## Solution: Tezza-style Vertical Grid

Replace horizontal scroll strips with a 3-column vertical grid organized by category, in both editor and camera views.

## Approach: "Tezza Puro"

### Shared Component: PresetGridView

A single reusable `PresetGridView` that adapts to both editor and camera contexts.

**Props:**
- `presets: [FilterPreset]` — filters to display
- `selectedPresetId: String?` — active filter
- `thumbnails: [String: UIImage]?` — real photo thumbnails (editor) or nil (camera uses static placeholders)
- `isPro: Bool` — for PRO badges
- `showIntensitySlider: Bool` — true in editor, false in camera
- `presetIntensity: Binding<Double>` — slider binding
- Callbacks: `onSelect`, `onDeselect`, `onLockedTapped`, `onIntensityChange`

**Grid specs:**
- 3 columns, 10pt spacing
- Thumbnails: ~105pt square (adaptive to screen width)
- Corner radius: 10pt
- Name: `.caption`, `.semibold`, below thumbnail
- Selection: `foticoPrimary` 2.5pt border
- PRO badge: top-right corner lock overlay
- "Original" as first grid item (not a category chip)
- Category chips: horizontal scroll above the grid (same style as current)

### Editor Integration

The `toolPanel` keeps its ~280pt height. When tool is `.presets`, it shows `PresetGridView` with vertical scroll inside that space. The intensity slider appears at the top when a preset is selected.

```
┌─────────────────────────────────┐
│  Intensidad ──────●───── 75%   │  ← only when preset selected
│  [Todos] [Película] [Cálidos]..│  ← category chips
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │thumb │ │thumb │ │thumb │   │  3-col LazyVGrid
│  │ E1   │ │ E2   │ │ E3   │   │  with real photo thumbnails
│  └──────┘ └──────┘ └──────┘   │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  └──────┘ └──────┘ └──────┘   │
└─────────────────────────────────┘
│ Presets │ Ajustes │ Efectos │...│  ← ToolBarView unchanged
```

### Camera Integration

Remove the horizontal preset strip. Add a "Filtros" button above the bottom controls that opens a half-sheet with `PresetGridView`.

**Button behavior:**
- Shows "Filtros" when no filter active, shows filter name when active (e.g. "Kodak")
- Tapping opens a `.sheet` with `.presentationDetents([.medium, .large])`
- `.presentationBackgroundInteraction(.enabled)` keeps camera active behind sheet

**Sheet content:**
- Same `PresetGridView` but without intensity slider (`showIntensitySlider: false`)
- Static thumbnails (no live preview per-thumbnail — too heavy for camera)
- Sheet stays open after selection so user can browse; drag down to minimize/close

```
┌─────────────────────────────────┐
│         LIVE PREVIEW            │
│         (filter applied)        │
├─────────────────────────────────┤  .medium detent
│  [Todos] [Película] [Cálidos]..│
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │  E1  │ │  E2  │ │  E3  │   │  static thumbnails
│  └──────┘ └──────┘ └──────┘   │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  └──────┘ └──────┘ └──────┘   │
└─────────────────────────────────┘
```

## Files Changed

| File | Action |
|------|--------|
| `Views/Editor/PresetGridView.swift` | NEW — shared grid component |
| `Views/Editor/PresetStripView.swift` | DELETE (replaced) |
| `Views/Camera/CameraPresetStripView.swift` | DELETE (replaced) |
| `Views/MainEditorView.swift` | MODIFY — use PresetGridView in toolPanel |
| `Views/Camera/CameraView.swift` | MODIFY — remove strip, add Filtros button + sheet |
| `Fotico.xcodeproj/project.pbxproj` | MODIFY — add/remove file references |

## Not Changed

- `ImageFilterService`, `PhotoEditorViewModel`, `FilterPreset`, `ToolBarView`, `CameraViewModel` — no logic changes needed.
