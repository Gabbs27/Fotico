# Motion Blur with Paintable Mask — Design

## Context

Inspired by Labbet's Motion Blur effect with mask painting. Users can apply directional motion blur to photos and selectively paint which areas receive the blur using a brush/eraser tool.

## Architecture

**Approach:** CIMotionBlur (CoreImage) + Metal MaskComposite shader

- `CIMotionBlur` for the directional blur (Apple's optimized implementation)
- Custom Metal shader for compositing original + blurred images using a painted mask
- Mask feathering via gaussian blur for professional-quality soft edges

## New Effect: `motionBlur`

Added to `EffectType` enum in a new "Blur" category. When selected, the effects panel shows additional controls beyond the standard intensity slider.

## Controls

1. **Direction slider** (0-360 degrees) — angle of the motion blur
2. **Amount/Intensity slider** (0-1) — blur radius
3. **Mask toggle** (ON/OFF) — enables painting mode
4. **Brush/Eraser toggle** — when mask ON, switch between painting blur areas and erasing them
5. **Brush size slider** — adjustable brush radius

## Data Model

In `EditState`, add:
- `motionBlurAngle: Double` (0-360, default 0 = horizontal)
- `motionBlurMask: Data?` (serialized PNG of the mask texture, nil = no mask = full-image blur)

The existing `motionBlur` intensity in the effects dictionary is already handled by `EditState`'s effect intensity system. The angle and mask are additional parameters specific to this effect.

## Rendering Pipeline

```
Original Image
    |
    v
CIMotionBlur(angle: radians, radius: intensity * maxRadius)
    |
    v (blurred image)
Has mask?
    YES -> Metal MaskComposite(original, blurred, mask)
           - mask alpha=1 -> show blurred
           - mask alpha=0 -> show original
           - Feathered edges via gaussian blur on mask
    NO  -> Blend original + blurred at intensity (existing blendImages method)
```

### Max Blur Radius

Scale to image resolution: `maxRadius = max(imageWidth, imageHeight) * 0.03` (approximately 36px on a 1200px proxy image, up to ~120px on a 4000px export).

## Mask Painting UI

### MaskPaintingView (New SwiftUI View)

When MASK is ON, overlays the image preview:

- Semi-transparent colored overlay (e.g., red at 30% opacity) showing painted mask areas
- User draws with finger using `DragGesture`
- Strokes rendered to an offscreen `CGContext` (same size as proxy image)
- White = blur applied, Black = no blur
- Brush mode: paints white strokes
- Eraser mode: paints black strokes (clear composite mode)
- Brush size adjustable via slider

### Mask Feathering

Before compositing, apply a small gaussian blur (radius ~3-5px) to the mask texture. This creates soft, professional-looking edges rather than hard paint strokes.

### Mask Serialization

- Stored as grayscale PNG in `EditState.motionBlurMask: Data?`
- Loaded as `CIImage` for the Metal composite shader
- Saved/loaded with project via `Codable`

## Metal Shader: MaskCompositeShader.metal

```metal
kernel void maskComposite(
    texture2d<float, access::read> original,
    texture2d<float, access::read> blurred,
    texture2d<float, access::read> mask,
    texture2d<float, access::write> output,
    uint2 gid [[thread_position_in_grid]]
) {
    float4 origColor = original.read(gid);
    float4 blurColor = blurred.read(gid);
    float maskValue = mask.read(gid).r; // grayscale mask
    output.write(mix(origColor, blurColor, maskValue), gid);
}
```

## Files to Create/Modify

| File | Change |
|------|--------|
| `Fotico/Models/EffectType.swift` | Add `.motionBlur` case in new "Blur" category |
| `Fotico/Models/EditState.swift` | Add `motionBlurAngle: Double`, `motionBlurMask: Data?` |
| `Fotico/Services/ImageFilterService.swift` | Add `applyMotionBlur()` method with CIMotionBlur + mask compositing |
| `Fotico/Services/MetalKernelService.swift` | Add `maskCompositeKernel` pipeline + `applyMaskComposite()` method |
| `Fotico/Metal/MaskCompositeShader.metal` | New Metal compute shader for mask-based compositing |
| `Fotico/Views/Editor/EffectsPanelView.swift` | Conditional UI for direction slider + mask controls when motionBlur selected |
| `Fotico/Views/Editor/MaskPaintingView.swift` | New view — overlay for painting mask with finger gestures |
| `Fotico/ViewModels/PhotoEditorViewModel.swift` | Mask state management, brush/eraser mode, mask CGContext |

## Performance Considerations

- Mask painting operates on the proxy image (1200px max), not full resolution
- CIMotionBlur is GPU-accelerated via CoreImage
- Metal composite is a single-pass operation
- Mask CGContext is created once and reused during painting
- On export, mask is scaled up to match full-resolution image

## Edge Cases

- No mask painted but MASK is ON → treat as full blur (same as MASK OFF)
- User toggles MASK OFF → mask data preserved but not applied (can toggle back ON)
- User changes blur direction/amount → re-render blur, recomposite with existing mask
- Project save/load → mask PNG serialized in EditState, round-trips through Codable
