# Motion Blur with Paintable Mask — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Motion Blur effect with directional control and a paintable mask that lets users selectively blur parts of their photos.

**Architecture:** CIMotionBlur for the blur + a new Metal compute shader for mask-based compositing. A new SwiftUI overlay view handles finger painting of the mask. The mask is a grayscale CGImage stored as PNG Data in EditState.

**Tech Stack:** Swift/SwiftUI, CoreImage (CIMotionBlur), Metal compute shaders, CGContext for mask painting

---

### Task 1: Create MaskCompositeShader.metal

**Files:**
- Create: `Fotico/Metal/MaskCompositeShader.metal`

**Step 1: Write the Metal shader**

Create `Fotico/Metal/MaskCompositeShader.metal`:

```metal
#include <metal_stdlib>
using namespace metal;

/// Composites two images using a grayscale mask.
/// Where mask is white (1.0) → show effect image.
/// Where mask is black (0.0) → show original image.
/// Intermediate values blend smoothly.
kernel void maskComposite(
    texture2d<float, access::read> original   [[texture(0)]],
    texture2d<float, access::read> effect     [[texture(1)]],
    texture2d<float, access::read> mask       [[texture(2)]],
    texture2d<float, access::write> output    [[texture(3)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) return;

    // Sample mask — scale UV if mask dimensions differ from output
    float2 maskUV = float2(gid) / float2(output.get_width(), output.get_height());
    uint2 maskPos = uint2(maskUV * float2(mask.get_width(), mask.get_height()));
    maskPos = min(maskPos, uint2(mask.get_width() - 1, mask.get_height() - 1));

    float4 origColor = original.read(gid);
    float4 effectColor = effect.read(gid);
    float maskValue = mask.read(maskPos).r;

    output.write(mix(origColor, effectColor, maskValue), gid);
}
```

**Step 2: Register in Xcode project (project.pbxproj)**

Add the new `.metal` file to PBXBuildFile, PBXFileReference, Metal group children, and Sources build phase — following the same pattern as `GrainShader.metal`, `LightLeakShader.metal`, and `BloomShader.metal`.

Use these IDs:
- PBXBuildFile: `MB01AABB00CC11DD22EE33FF /* MaskCompositeShader.metal in Sources */`
- PBXFileReference: `MB01AA00BB11CC22DD33EE44 /* MaskCompositeShader.metal */`
- fileRef format: `{isa = PBXFileReference; lastKnownFileType = sourcecode.metal; path = MaskCompositeShader.metal; sourceTree = "<group>"; }`

**Step 3: Build to verify shader compiles**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Metal/MaskCompositeShader.metal Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add MaskComposite Metal shader for mask-based image compositing"
```

---

### Task 2: Add `motionBlur` to EffectType + EffectCategory

**Files:**
- Modify: `Fotico/Models/EffectType.swift`

**Step 1: Add a new `blur` category to EffectCategory**

In `EffectCategory` enum, add a new case after `pro`:

```swift
case blur
```

And in `displayName`:
```swift
case .blur: return "Blur"
```

And in `icon`:
```swift
case .blur: return "aqi.low"
```

**Step 2: Add `motionBlur` case to EffectType**

Add after `letterbox`:

```swift
case motionBlur
```

In `displayName`:
```swift
case .motionBlur: return "Motion Blur"
```

In `icon`:
```swift
case .motionBlur: return "lines.measurement.horizontal"
```

In `category`:
```swift
case .motionBlur: return .blur
```

**Step 3: Build to verify — expect compiler errors in switch statements**

Run build — fix any exhaustive switch errors in:
- `PhotoEditorViewModel.swift` (`updateEffect` and `effectIntensity`)
- `ImageFilterService.swift` (`applyEffects`)

For now, add placeholder cases:
- In `updateEffect`: `case .motionBlur: editState.motionBlurIntensity = intensity` (will exist after Task 3)
- In `effectIntensity`: `case .motionBlur: return editState.motionBlurIntensity`

**Step 4: Commit**

```bash
git add Fotico/Models/EffectType.swift
git commit -m "feat: add motionBlur effect type with blur category"
```

---

### Task 3: Add Motion Blur properties to EditState

**Files:**
- Modify: `Fotico/Models/EditState.swift`

**Step 1: Add new properties after `letterboxIntensity`**

```swift
// Motion Blur
var motionBlurIntensity: Double = 0.0    // 0.0...1.0
var motionBlurAngle: Double = 0.0        // 0...360 degrees
var motionBlurMaskEnabled: Bool = false
var motionBlurMask: Data? = nil           // PNG of grayscale mask
```

**Step 2: Update `isDefault` computed property**

Add to the `isDefault` check:
```swift
&& motionBlurIntensity == 0.0
&& motionBlurAngle == 0.0
&& motionBlurMaskEnabled == false
&& motionBlurMask == nil
```

**Step 3: Update `reset()` method**

Add to reset:
```swift
motionBlurIntensity = 0.0
motionBlurAngle = 0.0
motionBlurMaskEnabled = false
motionBlurMask = nil
```

**Step 4: Build to verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Fotico/Models/EditState.swift
git commit -m "feat: add motionBlur properties to EditState"
```

---

### Task 4: Wire up motionBlur in PhotoEditorViewModel

**Files:**
- Modify: `Fotico/ViewModels/PhotoEditorViewModel.swift`

**Step 1: Add motionBlur cases to updateEffect and effectIntensity**

In `updateEffect(_ effect:intensity:)`, add:
```swift
case .motionBlur: editState.motionBlurIntensity = intensity
```

In `effectIntensity(for:)`, add:
```swift
case .motionBlur: return editState.motionBlurIntensity
```

**Step 2: Add mask painting state**

Add published properties for mask painting UI:

```swift
@Published var isMaskPainting: Bool = false
@Published var maskBrushMode: MaskBrushMode = .brush
@Published var maskBrushSize: CGFloat = 40.0

enum MaskBrushMode {
    case brush   // paints white (apply effect)
    case eraser  // paints black (remove effect)
}
```

**Step 3: Add mask management methods**

```swift
// MARK: - Motion Blur Mask

func updateMotionBlurAngle(_ angle: Double) {
    pushUndo()
    editState.motionBlurAngle = angle
    scheduleRender()
}

func toggleMotionBlurMask() {
    pushUndo()
    editState.motionBlurMaskEnabled.toggle()
    scheduleRender()
}

func updateMotionBlurMask(_ maskData: Data?) {
    editState.motionBlurMask = maskData
    scheduleRender()
}

func clearMotionBlurMask() {
    pushUndo()
    editState.motionBlurMask = nil
    editState.motionBlurMaskEnabled = false
    scheduleRender()
}
```

**Step 4: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Fotico/ViewModels/PhotoEditorViewModel.swift
git commit -m "feat: wire motionBlur state management in PhotoEditorViewModel"
```

---

### Task 5: Add maskComposite pipeline to MetalKernelService

**Files:**
- Modify: `Fotico/Services/MetalKernelService.swift`

**Step 1: Add the mask composite pipeline**

Add a new pipeline property alongside existing ones:

```swift
private let maskCompositePipeline: MTLComputePipelineState
```

In `init()`, load it from the library alongside existing pipelines:

```swift
maskCompositePipeline = try library.makeComputePipelineState(function: library.makeFunction(name: "maskComposite")!)
```

**Step 2: Add the `applyMaskComposite` method**

```swift
func applyMaskComposite(original: CIImage, effect: CIImage, mask: CIImage) async -> CIImage? {
    let width = Int(original.extent.width)
    let height = Int(original.extent.height)

    guard let origTex = textureFromCIImage(original, width: width, height: height),
          let effectTex = textureFromCIImage(effect, width: width, height: height),
          let maskTex = textureFromCIImage(mask, width: Int(mask.extent.width), height: Int(mask.extent.height)),
          let outputTex = getPooledTexture(width: width, height: height) else {
        return nil
    }

    return await withCheckedContinuation { continuation in
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            continuation.resume(returning: nil)
            return
        }

        encoder.setComputePipelineState(maskCompositePipeline)
        encoder.setTexture(origTex, index: 0)
        encoder.setTexture(effectTex, index: 1)
        encoder.setTexture(maskTex, index: 2)
        encoder.setTexture(outputTex, index: 3)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (width + 15) / 16,
            height: (height + 15) / 16,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.addCompletedHandler { _ in
            let ciImage = CIImage(mtlTexture: outputTex, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])
            continuation.resume(returning: ciImage?.oriented(.downMirrored))
        }
        commandBuffer.commit()
    }
}
```

Note: This method follows the same pattern as existing Metal methods in MetalKernelService (e.g., `applyGrain`, `applyBloom`). Look at how they convert CIImage to MTLTexture and back — reuse the existing `textureFromCIImage` and `getPooledTexture` helper methods.

**Step 3: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Services/MetalKernelService.swift
git commit -m "feat: add maskComposite pipeline to MetalKernelService"
```

---

### Task 6: Add Motion Blur rendering to ImageFilterService

**Files:**
- Modify: `Fotico/Services/ImageFilterService.swift`

**Step 1: Add CIMotionBlur filter instance**

Add to the cached filter list at the top of the class:

```swift
private let motionBlurFilter = CIFilter(name: "CIMotionBlur")!
```

**Step 2: Add applyMotionBlur method**

Add this method after the existing effect methods:

```swift
private func applyMotionBlur(to image: CIImage, state: EditState) -> CIImage {
    guard state.motionBlurIntensity > 0 else { return image }

    // Convert angle from degrees to radians
    let angleRadians = state.motionBlurAngle * .pi / 180.0

    // Scale radius to image size (max ~3% of largest dimension)
    let maxDim = max(image.extent.width, image.extent.height)
    let maxRadius = maxDim * 0.03
    let radius = state.motionBlurIntensity * maxRadius

    motionBlurFilter.setValue(image, forKey: kCIInputImageKey)
    motionBlurFilter.setValue(radius, forKey: kCIInputRadiusKey)
    motionBlurFilter.setValue(angleRadians, forKey: kCIInputAngleKey)

    guard let blurred = motionBlurFilter.outputImage else { return image }

    // If mask is enabled and exists, composite using mask
    if state.motionBlurMaskEnabled, let maskData = state.motionBlurMask,
       let maskUIImage = UIImage(data: maskData),
       let maskCGImage = maskUIImage.cgImage {

        let maskCI = CIImage(cgImage: maskCGImage)

        // Apply small gaussian blur to mask for feathered edges
        let featheredMask: CIImage
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(maskCI, forKey: kCIInputImageKey)
            blurFilter.setValue(4.0, forKey: kCIInputRadiusKey)
            featheredMask = blurFilter.outputImage?.cropped(to: maskCI.extent) ?? maskCI
        } else {
            featheredMask = maskCI
        }

        // Use CIBlendWithMask for compositing (CoreImage, no Metal needed for this)
        if let blendFilter = CIFilter(name: "CIBlendWithMask") {
            blendFilter.setValue(blurred.cropped(to: image.extent), forKey: kCIInputImageKey)
            blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
            blendFilter.setValue(featheredMask, forKey: kCIInputMaskImageKey)
            if let result = blendFilter.outputImage {
                return result.cropped(to: image.extent)
            }
        }
    }

    // No mask — blend at intensity
    return blendImages(base: image, overlay: blurred.cropped(to: image.extent), intensity: state.motionBlurIntensity)
}
```

**Step 3: Call applyMotionBlur in applyEffects**

In the `applyEffects` method, add the motion blur call. Add it **before** the existing vignette call (motion blur should be applied early so other effects layer on top):

```swift
// Motion Blur (with optional mask)
result = applyMotionBlur(to: result, state: state)
```

**Step 4: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Fotico/Services/ImageFilterService.swift
git commit -m "feat: add Motion Blur rendering with mask compositing via CIBlendWithMask"
```

---

### Task 7: Create MaskPaintingView

**Files:**
- Create: `Fotico/Views/Editor/MaskPaintingView.swift`

**Step 1: Create the mask painting overlay view**

```swift
import SwiftUI

/// Overlay view for painting a motion blur mask.
/// Captures finger gestures and renders strokes to an offscreen CGContext.
struct MaskPaintingView: View {
    @ObservedObject var viewModel: PhotoEditorViewModel
    let imageSize: CGSize   // Size of the proxy image
    let displaySize: CGSize // Size of the preview on screen

    @State private var maskContext: CGContext?
    @State private var maskImage: UIImage?
    @State private var lastPoint: CGPoint?

    var body: some View {
        ZStack {
            // Semi-transparent overlay showing mask
            if let maskImage {
                Image(uiImage: maskImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .opacity(0.35)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }

            // Gesture capture area
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = convertToImageCoordinates(value.location)
                            if let last = lastPoint {
                                drawLine(from: last, to: point)
                            } else {
                                drawLine(from: point, to: point)
                            }
                            lastPoint = point
                            updateMaskImage()
                        }
                        .onEnded { _ in
                            lastPoint = nil
                            saveMaskToState()
                        }
                )
        }
        .onAppear {
            initializeContext()
            loadExistingMask()
        }
    }

    // MARK: - Context Management

    private func initializeContext() {
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return }

        // Start with black (no blur applied anywhere)
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        maskContext = ctx
    }

    private func loadExistingMask() {
        guard let data = viewModel.editState.motionBlurMask,
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else { return }

        maskContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: Int(imageSize.width), height: Int(imageSize.height)))
        updateMaskImage()
    }

    // MARK: - Drawing

    private func drawLine(from: CGPoint, to: CGPoint) {
        guard let ctx = maskContext else { return }

        let brushRadius = viewModel.maskBrushSize / 2.0

        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(brushRadius * 2)

        switch viewModel.maskBrushMode {
        case .brush:
            ctx.setStrokeColor(gray: 1, alpha: 1) // White = apply blur
            ctx.setBlendMode(.normal)
        case .eraser:
            ctx.setStrokeColor(gray: 0, alpha: 1) // Black = no blur
            ctx.setBlendMode(.normal)
        }

        // Flip Y because CGContext has origin at bottom-left
        let flippedFrom = CGPoint(x: from.x, y: imageSize.height - from.y)
        let flippedTo = CGPoint(x: to.x, y: imageSize.height - to.y)

        ctx.beginPath()
        ctx.move(to: flippedFrom)
        ctx.addLine(to: flippedTo)
        ctx.strokePath()
    }

    private func convertToImageCoordinates(_ screenPoint: CGPoint) -> CGPoint {
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height
        return CGPoint(x: screenPoint.x * scaleX, y: screenPoint.y * scaleY)
    }

    // MARK: - Image Updates

    private func updateMaskImage() {
        guard let ctx = maskContext, let cgImage = ctx.makeImage() else { return }
        // Tint the mask for display (show painted areas in red)
        maskImage = UIImage(cgImage: cgImage)
    }

    private func saveMaskToState() {
        guard let ctx = maskContext, let cgImage = ctx.makeImage() else { return }
        let uiImage = UIImage(cgImage: cgImage)
        let pngData = uiImage.pngData()
        viewModel.updateMotionBlurMask(pngData)
    }
}
```

**Step 2: Register in Xcode project (project.pbxproj)**

Add the new `.swift` file following the same pattern as other Editor views. Use IDs:
- PBXBuildFile: `MP01AABB00CC11DD22EE33FF /* MaskPaintingView.swift in Sources */`
- PBXFileReference: `MP01AA00BB11CC22DD33EE44 /* MaskPaintingView.swift */`

Add to the Editor group children and Sources build phase.

**Step 3: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Views/Editor/MaskPaintingView.swift Fotico.xcodeproj/project.pbxproj
git commit -m "feat: add MaskPaintingView for finger-based mask painting"
```

---

### Task 8: Update EffectsPanelView with Motion Blur controls

**Files:**
- Modify: `Fotico/Views/Editor/EffectsPanelView.swift`

**Step 1: Add motion blur-specific controls**

When `selectedEffect == .motionBlur`, show additional controls below the intensity slider:

1. **Direction slider** (0-360)
2. **Mask toggle button** (ON/OFF)
3. **Brush/Eraser toggle** (when mask is ON)
4. **Brush size slider** (when mask is ON)
5. **Clear mask button** (when mask is ON and has data)

Add these after the existing intensity slider section, wrapped in a conditional:

```swift
// Motion Blur extra controls
if selectedEffect == .motionBlur {
    VStack(spacing: 12) {
        // Direction
        HStack {
            Text("Dirección")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(viewModel.editState.motionBlurAngle))°")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        Slider(value: Binding(
            get: { viewModel.editState.motionBlurAngle },
            set: { viewModel.updateMotionBlurAngle($0) }
        ), in: 0...360, step: 1)
        .tint(.primary)

        // Mask controls
        HStack(spacing: 12) {
            Button {
                viewModel.toggleMotionBlurMask()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.editState.motionBlurMaskEnabled ? "paintbrush.fill" : "paintbrush")
                    Text(viewModel.editState.motionBlurMaskEnabled ? "MASK: ON" : "MASK: OFF")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.editState.motionBlurMaskEnabled ? Color.primary : Color.clear)
                .foregroundStyle(viewModel.editState.motionBlurMaskEnabled ? Color(UIColor.systemBackground) : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
            }

            if viewModel.editState.motionBlurMaskEnabled {
                // Brush/Eraser toggle
                Button {
                    viewModel.maskBrushMode = viewModel.maskBrushMode == .brush ? .eraser : .brush
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.maskBrushMode == .brush ? "paintbrush.pointed.fill" : "eraser.fill")
                        Text(viewModel.maskBrushMode == .brush ? "Pincel" : "Borrar")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Clear mask
                if viewModel.editState.motionBlurMask != nil {
                    Button {
                        viewModel.clearMotionBlurMask()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .padding(6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }

            Spacer()
        }

        if viewModel.editState.motionBlurMaskEnabled {
            // Brush size slider
            HStack {
                Text("Tamaño")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $viewModel.maskBrushSize, in: 10...100, step: 1)
                    .tint(.primary)
                Text("\(Int(viewModel.maskBrushSize))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }
        }
    }
    .padding(.horizontal)
}
```

**Step 2: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Fotico/Views/Editor/EffectsPanelView.swift
git commit -m "feat: add Motion Blur direction, mask, and brush controls to EffectsPanelView"
```

---

### Task 9: Integrate MaskPaintingView into MainEditorView

**Files:**
- Modify: `Fotico/Views/MainEditorView.swift`

**Step 1: Add the mask painting overlay**

Find where `ImagePreviewView` is displayed. Add a conditional overlay when motion blur mask painting is active:

```swift
// After ImagePreviewView, as an overlay
.overlay {
    if viewModel.editState.motionBlurMaskEnabled && viewModel.currentTool == .effects {
        GeometryReader { geometry in
            MaskPaintingView(
                viewModel: viewModel,
                imageSize: viewModel.proxyImageSize,
                displaySize: geometry.size
            )
        }
    }
}
```

**Step 2: Expose proxyImageSize from PhotoEditorViewModel**

In `PhotoEditorViewModel`, add a computed property:

```swift
var proxyImageSize: CGSize {
    guard let proxy = proxyCIImage else { return .zero }
    return proxy.extent.size
}
```

Note: `proxyCIImage` is private — if it's private, either make `proxyImageSize` use the `editedCIImage`'s extent or make the proxy accessible. Check the actual code and adapt.

**Step 3: Build and verify**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Fotico/Views/MainEditorView.swift Fotico/ViewModels/PhotoEditorViewModel.swift
git commit -m "feat: integrate MaskPaintingView overlay in MainEditorView"
```

---

### Task 10: Final build verification and cleanup

**Step 1: Clean build**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Verify effect count**

EffectType should now have 15 effects across 5 categories (film, lens, stylize, pro, blur).

**Step 3: Final commit if needed**

```bash
git add -A
git commit -m "feat: complete Motion Blur with paintable mask"
```
