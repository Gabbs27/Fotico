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
    r = clamp(r + 0.03)
    g = clamp(g + 0.02)
    b = clamp(b + 0.01)
    mid = 0.5
    r = mid + (r - mid) * 0.78
    g = mid + (g - mid) * 0.78
    b = mid + (b - mid) * 0.78
    return r, g, b


# ── Noir: B&W editorial, lifted blacks, warm shadow tint ──
def noir_transform(r, g, b):
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    lum = apply_curve(lum, 0.07, 0.95, 1.1)
    mid = 0.5
    lum = mid + (lum - mid) * 0.90
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
