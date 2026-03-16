# Soft Focus Collection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a new "Soft Focus" preset category with 6 editorial-style presets (Muse, Haze, Matte, Dusk, Ivory, Noir) inspired by the Labbet app aesthetic.

**Architecture:** Each preset uses a LUT `.cube` file for color grading + existing effect parameters (grain, vignette, softDiffusion, bloom). New `softFocus` case added to `PresetCategory` enum. No changes to filter pipeline code.

**Tech Stack:** Swift/SwiftUI, CoreImage LUTs (.cube format), Xcode project file (pbxproj)

---

### Task 1: Generate 6 LUT `.cube` files

**Files:**
- Create: `scripts/generate_soft_focus_luts.py`
- Create: `Fotico/Resources/LUTs/sf_muse.cube`
- Create: `Fotico/Resources/LUTs/sf_haze.cube`
- Create: `Fotico/Resources/LUTs/sf_matte.cube`
- Create: `Fotico/Resources/LUTs/sf_dusk.cube`
- Create: `Fotico/Resources/LUTs/sf_ivory.cube`
- Create: `Fotico/Resources/LUTs/sf_noir.cube`

**Step 1: Create the Python LUT generator script**

```python
#!/usr/bin/env python3
"""Generate 6 Soft Focus .cube LUT files for Lumé app."""

import os
import math

LUT_SIZE = 33
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Fotico", "Resources", "LUTs")


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def smoothstep(edge0, edge1, x):
    t = clamp((x - edge0) / (edge1 - edge0))
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def apply_curve(v, black_point, white_point, gamma=1.0):
    """Map [0,1] -> [black_point, white_point] with optional gamma."""
    v = clamp(v)
    v = pow(v, gamma)
    return lerp(black_point, white_point, v)


def desaturate(r, g, b, amount):
    """Desaturate by amount (0=original, 1=fully gray)."""
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return (lerp(r, lum, amount), lerp(g, lum, amount), lerp(b, lum, amount))


def warm_shift(r, g, b, amount):
    """Shift toward warm (add red/yellow, reduce blue)."""
    return (clamp(r + amount * 0.06), clamp(g + amount * 0.02), clamp(b - amount * 0.05))


def cool_shift(r, g, b, amount):
    """Shift toward cool (add blue, reduce red)."""
    return (clamp(r - amount * 0.04), clamp(g - amount * 0.01), clamp(b + amount * 0.06))


def write_cube(filename, title, transform_fn):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w") as f:
        f.write(f'TITLE "{title}"\n')
        f.write(f"LUT_3D_SIZE {LUT_SIZE}\n")
        f.write("DOMAIN_MIN 0.0 0.0 0.0\n")
        f.write("DOMAIN_MAX 1.0 1.0 1.0\n")
        for b_i in range(LUT_SIZE):
            for g_i in range(LUT_SIZE):
                for r_i in range(LUT_SIZE):
                    r = r_i / (LUT_SIZE - 1)
                    g = g_i / (LUT_SIZE - 1)
                    b = b_i / (LUT_SIZE - 1)
                    ro, go, bo = transform_fn(r, g, b)
                    f.write(f"{clamp(ro):.6f} {clamp(go):.6f} {clamp(bo):.6f}\n")
    print(f"  Written: {path}")


# ── Muse: Warm editorial, desaturated, lifted blacks ──
def muse_transform(r, g, b):
    r = apply_curve(r, 0.06, 0.94, 1.05)
    g = apply_curve(g, 0.05, 0.93, 1.05)
    b = apply_curve(b, 0.07, 0.90, 1.10)
    r, g, b = desaturate(r, g, b, 0.35)
    r, g, b = warm_shift(r, g, b, 0.7)
    # Slight S-curve for contained contrast
    mid = 0.5
    r = mid + (r - mid) * 0.85
    g = mid + (g - mid) * 0.85
    b = mid + (b - mid) * 0.80
    return r, g, b


# ── Haze: Dreamy fog, heavy fade, pushed highlights ──
def haze_transform(r, g, b):
    r = apply_curve(r, 0.10, 0.96, 0.90)
    g = apply_curve(g, 0.09, 0.95, 0.90)
    b = apply_curve(b, 0.10, 0.94, 0.92)
    r, g, b = desaturate(r, g, b, 0.40)
    r, g, b = warm_shift(r, g, b, 0.3)
    # Flatten contrast heavily
    mid = 0.5
    r = mid + (r - mid) * 0.70
    g = mid + (g - mid) * 0.70
    b = mid + (b - mid) * 0.70
    return r, g, b


# ── Matte: Flat magazine, lifted blacks, neutral ──
def matte_transform(r, g, b):
    r = apply_curve(r, 0.08, 0.92, 1.0)
    g = apply_curve(g, 0.08, 0.92, 1.0)
    b = apply_curve(b, 0.08, 0.91, 1.0)
    r, g, b = desaturate(r, g, b, 0.30)
    # Very flat contrast
    mid = 0.5
    r = mid + (r - mid) * 0.75
    g = mid + (g - mid) * 0.75
    b = mid + (b - mid) * 0.75
    return r, g, b


# ── Dusk: Cool twilight, blue/violet shadows ──
def dusk_transform(r, g, b):
    r = apply_curve(r, 0.05, 0.91, 1.08)
    g = apply_curve(g, 0.05, 0.92, 1.05)
    b = apply_curve(b, 0.08, 0.95, 0.95)
    r, g, b = desaturate(r, g, b, 0.30)
    r, g, b = cool_shift(r, g, b, 0.8)
    # Add violet to shadows
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    shadow_amt = 1.0 - smoothstep(0.0, 0.4, lum)
    r = clamp(r + shadow_amt * 0.03)
    b = clamp(b + shadow_amt * 0.05)
    mid = 0.5
    r = mid + (r - mid) * 0.85
    g = mid + (g - mid) * 0.85
    b = mid + (b - mid) * 0.82
    return r, g, b


# ── Ivory: Bright & airy, creamy highlights, heavy fade ──
def ivory_transform(r, g, b):
    r = apply_curve(r, 0.09, 0.98, 0.88)
    g = apply_curve(g, 0.08, 0.97, 0.88)
    b = apply_curve(b, 0.08, 0.95, 0.90)
    r, g, b = desaturate(r, g, b, 0.38)
    r, g, b = warm_shift(r, g, b, 0.5)
    # Brighten overall
    r = clamp(r + 0.03)
    g = clamp(g + 0.02)
    b = clamp(b + 0.01)
    # Mild contrast reduction
    mid = 0.5
    r = mid + (r - mid) * 0.78
    g = mid + (g - mid) * 0.78
    b = mid + (b - mid) * 0.78
    return r, g, b


# ── Noir: B&W editorial, lifted blacks, warm shadow tint ──
def noir_transform(r, g, b):
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    lum = apply_curve(lum, 0.07, 0.95, 1.1)
    # Medium contrast S-curve
    mid = 0.5
    lum = mid + (lum - mid) * 0.90
    # Slight warm tint in shadows
    shadow_amt = 1.0 - smoothstep(0.0, 0.35, lum)
    r_out = clamp(lum + shadow_amt * 0.02)
    g_out = clamp(lum + shadow_amt * 0.005)
    b_out = clamp(lum - shadow_amt * 0.01)
    return r_out, g_out, b_out


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("Generating Soft Focus LUTs...")
    write_cube("sf_muse.cube", "Muse", muse_transform)
    write_cube("sf_haze.cube", "Haze", haze_transform)
    write_cube("sf_matte.cube", "Matte", matte_transform)
    write_cube("sf_dusk.cube", "Dusk", dusk_transform)
    write_cube("sf_ivory.cube", "Ivory", ivory_transform)
    write_cube("sf_noir.cube", "Noir", noir_transform)
    print("Done! 6 LUT files generated.")
```

**Step 2: Run the script to generate .cube files**

Run: `python3 scripts/generate_soft_focus_luts.py`
Expected: 6 `.cube` files created in `Fotico/Resources/LUTs/`

**Step 3: Verify the generated files**

Run: `ls -la Fotico/Resources/LUTs/sf_*.cube && head -5 Fotico/Resources/LUTs/sf_muse.cube`
Expected: 6 files exist, each starts with `TITLE`, `LUT_3D_SIZE 33`, `DOMAIN_MIN`, `DOMAIN_MAX`

**Step 4: Commit**

```bash
git add scripts/generate_soft_focus_luts.py Fotico/Resources/LUTs/sf_*.cube
git commit -m "feat: generate 6 Soft Focus LUT files (Muse, Haze, Matte, Dusk, Ivory, Noir)"
```

---

### Task 2: Add `softFocus` category to PresetCategory enum

**Files:**
- Modify: `Fotico/Models/FilterPreset.swift:129-155` (PresetCategory enum)

**Step 1: Add the new enum case and display properties**

In `Fotico/Models/FilterPreset.swift`, add `case softFocus` after `case vintage` in the `PresetCategory` enum (line ~134).

Add to `displayName` switch:
```swift
case .softFocus: return "Soft Focus"
```

Add to `icon` switch:
```swift
case .softFocus: return "camera.filters"
```

**Step 2: Build to verify no compilation errors**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (the CaseIterable conformance may cause warnings about exhaustive switches elsewhere — fix any)

**Step 3: Commit**

```bash
git add Fotico/Models/FilterPreset.swift
git commit -m "feat: add softFocus category to PresetCategory enum"
```

---

### Task 3: Define 6 Soft Focus presets in allPresets

**Files:**
- Modify: `Fotico/Models/FilterPreset.swift:32-124` (allPresets array)

**Step 1: Add the 6 preset definitions after the Vintage section**

After line 123 (`vhs` preset), before the closing `]`, add:

```swift
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: Soft Focus
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FilterPreset(id: "sf_muse", name: "Muse",
                     category: .softFocus, lutFileName: "sf_muse.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.55, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.50, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.40, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.15, minValue: 0, maxValue: 1),
                     ], sortOrder: 400),
        FilterPreset(id: "sf_haze", name: "Haze",
                     category: .softFocus, lutFileName: "sf_haze.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.40, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.35, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.55, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.25, minValue: 0, maxValue: 1),
                     ], sortOrder: 401),
        FilterPreset(id: "sf_matte", name: "Matte",
                     category: .softFocus, lutFileName: "sf_matte.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.50, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.40, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.30, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.10, minValue: 0, maxValue: 1),
                     ], sortOrder: 402),
        FilterPreset(id: "sf_dusk", name: "Dusk",
                     category: .softFocus, lutFileName: "sf_dusk.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.45, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.45, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.35, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.20, minValue: 0, maxValue: 1),
                     ], sortOrder: 403),
        FilterPreset(id: "sf_ivory", name: "Ivory",
                     category: .softFocus, lutFileName: "sf_ivory.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.35, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.30, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.45, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.30, minValue: 0, maxValue: 1),
                     ], sortOrder: 404),
        FilterPreset(id: "sf_noir", name: "Noir",
                     category: .softFocus, lutFileName: "sf_noir.cube",
                     parameters: [
                         FilterParameter(key: "grain", value: 0.60, minValue: 0, maxValue: 1),
                         FilterParameter(key: "vignette", value: 0.55, minValue: 0, maxValue: 2),
                         FilterParameter(key: "softDiffusion", value: 0.25, minValue: 0, maxValue: 1),
                         FilterParameter(key: "bloom", value: 0.10, minValue: 0, maxValue: 1),
                     ], sortOrder: 405),
```

**Step 2: Commit**

```bash
git add Fotico/Models/FilterPreset.swift
git commit -m "feat: add 6 Soft Focus preset definitions"
```

---

### Task 4: Register LUT files in Xcode project

**Files:**
- Modify: `Fotico.xcodeproj/project.pbxproj`

**Step 1: Add PBXBuildFile entries**

After line 100 (last existing `LB00...` entry for `.cube`), add 6 new build file entries:

```
		LB0050BBBBBBBBBBBBBBBB /* sf_muse.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0050AAAAAAAAAAAAAAAA /* sf_muse.cube */; };
		LB0051BBBBBBBBBBBBBBBB /* sf_haze.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0051AAAAAAAAAAAAAAAA /* sf_haze.cube */; };
		LB0052BBBBBBBBBBBBBBBB /* sf_matte.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0052AAAAAAAAAAAAAAAA /* sf_matte.cube */; };
		LB0053BBBBBBBBBBBBBBBB /* sf_dusk.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0053AAAAAAAAAAAAAAAA /* sf_dusk.cube */; };
		LB0054BBBBBBBBBBBBBBBB /* sf_ivory.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0054AAAAAAAAAAAAAAAA /* sf_ivory.cube */; };
		LB0055BBBBBBBBBBBBBBBB /* sf_noir.cube in Resources */ = {isa = PBXBuildFile; fileRef = LR0055AAAAAAAAAAAAAAAA /* sf_noir.cube */; };
```

**Step 2: Add PBXFileReference entries**

After line 195 (last existing `LR00...` file reference for `.cube`), add:

```
		LR0050AAAAAAAAAAAAAAAA /* sf_muse.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_muse.cube; sourceTree = "<group>"; };
		LR0051AAAAAAAAAAAAAAAA /* sf_haze.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_haze.cube; sourceTree = "<group>"; };
		LR0052AAAAAAAAAAAAAAAA /* sf_matte.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_matte.cube; sourceTree = "<group>"; };
		LR0053AAAAAAAAAAAAAAAA /* sf_dusk.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_dusk.cube; sourceTree = "<group>"; };
		LR0054AAAAAAAAAAAAAAAA /* sf_ivory.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_ivory.cube; sourceTree = "<group>"; };
		LR0055AAAAAAAAAAAAAAAA /* sf_noir.cube */ = {isa = PBXFileReference; lastKnownFileType = text; path = sf_noir.cube; sourceTree = "<group>"; };
```

**Step 3: Add to LUTs group children**

In the LUTs group (around line 429-459), add the 6 new file references inside the `children` array, after the last existing `.cube` reference but before the closing `);`:

```
				LR0050AAAAAAAAAAAAAAAA /* sf_muse.cube */,
				LR0051AAAAAAAAAAAAAAAA /* sf_haze.cube */,
				LR0052AAAAAAAAAAAAAAAA /* sf_matte.cube */,
				LR0053AAAAAAAAAAAAAAAA /* sf_dusk.cube */,
				LR0054AAAAAAAAAAAAAAAA /* sf_ivory.cube */,
				LR0055AAAAAAAAAAAAAAAA /* sf_noir.cube */,
```

**Step 4: Add to Resources build phase**

In the PBXResourcesBuildPhase section (around line 517-547), add the 6 build file references:

```
				LB0050BBBBBBBBBBBBBBBB /* sf_muse.cube in Resources */,
				LB0051BBBBBBBBBBBBBBBB /* sf_haze.cube in Resources */,
				LB0052BBBBBBBBBBBBBBBB /* sf_matte.cube in Resources */,
				LB0053BBBBBBBBBBBBBBBB /* sf_dusk.cube in Resources */,
				LB0054BBBBBBBBBBBBBBBB /* sf_ivory.cube in Resources */,
				LB0055BBBBBBBBBBBBBBBB /* sf_noir.cube in Resources */,
```

**Step 5: Build to verify Xcode finds the LUTs**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Fotico.xcodeproj/project.pbxproj
git commit -m "feat: register 6 Soft Focus LUT files in Xcode project"
```

---

### Task 5: Verify full build and category display

**Step 1: Clean build**

Run: `xcodebuild -scheme Fotico -destination 'platform=iOS Simulator,name=iPhone 16' clean build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED with no warnings about missing resources

**Step 2: Verify preset count**

The `allPresets` array should now have 30 presets total (24 existing + 6 new). The `PresetCategory.allCases` should include `softFocus`, which means `CategoryChipView` and `PresetGridView` will automatically show the new category.

**Step 3: Final commit with all changes if anything was missed**

```bash
git add -A
git commit -m "feat: complete Soft Focus collection — 6 editorial presets"
```
