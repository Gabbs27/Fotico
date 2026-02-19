#!/usr/bin/env python3
"""
Generate Lumé Featured LUTs with professional color grading formulas.

Vintage: Retro/70s - heavy grain + matte blacks + warm earth tones
Mood: Editorial - desaturated + killed greens/blues + high contrast
Lush: Summer/tropical - warm + vibrant + cyan blues + orange yellows
Dream: Ethereal/romantic - soft glow + pastel + lifted shadows
Golden: Golden hour - warm sunlight + bronzed skin + amber tones
"""

import numpy as np
import os

LUT_SIZE = 33
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Fotico', 'Resources', 'LUTs')


def identity_lut(size):
    """Create identity 3D LUT."""
    lut = np.zeros((size, size, size, 3))
    for b in range(size):
        for g in range(size):
            for r in range(size):
                lut[b, g, r] = [r / (size - 1), g / (size - 1), b / (size - 1)]
    return lut


def apply_curve(x, points):
    """Apply a tone curve defined by control points using linear interpolation."""
    points = sorted(points, key=lambda p: p[0])
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return np.interp(x, xs, ys)


def adjust_exposure(lut, ev):
    """Adjust exposure in EV stops."""
    factor = 2.0 ** ev
    return np.clip(lut * factor, 0, 1)


def adjust_contrast(lut, amount):
    """Adjust contrast. amount in [-100, 100] range like Lightroom."""
    # Convert to -1..1 range
    t = amount / 100.0
    # S-curve contrast
    mid = 0.5
    if t > 0:
        lut = mid + (lut - mid) * (1 + t * 0.8)
    else:
        lut = mid + (lut - mid) * (1 + t * 0.5)
    return np.clip(lut, 0, 1)


def adjust_saturation(lut, amount):
    """Adjust saturation. amount in [-100, 100] range."""
    t = 1.0 + amount / 100.0
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    result = lut.copy()
    for c in range(3):
        result[..., c] = luminance + (lut[..., c] - luminance) * t
    return np.clip(result, 0, 1)


def adjust_vibrance(lut, amount):
    """Adjust vibrance - boosts less saturated colors more."""
    t = amount / 100.0
    result = lut.copy()
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    for c in range(3):
        sat = np.abs(lut[..., c] - luminance)
        # Less saturated pixels get more boost
        boost = 1.0 + t * (1.0 - np.clip(sat * 3, 0, 1))
        result[..., c] = luminance + (lut[..., c] - luminance) * boost
    return np.clip(result, 0, 1)


def adjust_highlights(lut, amount):
    """Adjust highlights. amount in [-100, 100]."""
    t = amount / 100.0
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    # Only affect bright areas
    mask = np.clip((luminance - 0.5) * 2, 0, 1) ** 1.5
    result = lut.copy()
    for c in range(3):
        result[..., c] = lut[..., c] + mask * t * 0.3
    return np.clip(result, 0, 1)


def adjust_shadows(lut, amount):
    """Adjust shadows. amount in [-100, 100]."""
    t = amount / 100.0
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    # Only affect dark areas
    mask = np.clip(1.0 - luminance * 2, 0, 1) ** 1.5
    result = lut.copy()
    for c in range(3):
        result[..., c] = lut[..., c] + mask * t * 0.3
    return np.clip(result, 0, 1)


def adjust_whites(lut, amount):
    """Adjust whites."""
    t = amount / 100.0
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    mask = np.clip((luminance - 0.7) * 3.3, 0, 1) ** 2
    result = lut.copy()
    for c in range(3):
        result[..., c] = lut[..., c] + mask * t * 0.25
    return np.clip(result, 0, 1)


def adjust_blacks(lut, amount):
    """Adjust blacks. Negative = deeper blacks."""
    t = amount / 100.0
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]
    mask = np.clip(1.0 - luminance * 3.3, 0, 1) ** 2
    result = lut.copy()
    for c in range(3):
        result[..., c] = lut[..., c] + mask * t * 0.2
    return np.clip(result, 0, 1)


def adjust_temperature(lut, amount):
    """Adjust color temperature. Positive = warm (yellow), negative = cool (blue)."""
    t = amount / 100.0
    result = lut.copy()
    # Warm: boost red, reduce blue
    result[..., 0] = lut[..., 0] + t * 0.06  # Red
    result[..., 2] = lut[..., 2] - t * 0.06  # Blue
    # Slight green shift for natural warmth
    result[..., 1] = lut[..., 1] + t * 0.015
    return np.clip(result, 0, 1)


def adjust_tint(lut, amount):
    """Adjust tint. Positive = magenta/pink, negative = green."""
    t = amount / 100.0
    result = lut.copy()
    result[..., 1] = lut[..., 1] - t * 0.04  # Green
    result[..., 0] = lut[..., 0] + t * 0.02  # Red (for pink)
    result[..., 2] = lut[..., 2] + t * 0.02  # Blue (for magenta)
    return np.clip(result, 0, 1)


def lift_blacks(lut, amount):
    """Lift the black point - creates matte/faded look.
    amount: how much to lift (0-1), typical 0.03-0.08"""
    result = lut.copy()
    for c in range(3):
        result[..., c] = amount + lut[..., c] * (1.0 - amount)
    return np.clip(result, 0, 1)


def hsl_adjust(lut, target_hue_range, hue_shift=0, sat_shift=0, lum_shift=0):
    """
    HSL adjustment for specific hue range.
    target_hue_range: (min_hue, max_hue) in degrees 0-360
    shifts in [-1, 1] range
    """
    result = lut.copy()
    r, g, b = lut[..., 0], lut[..., 1], lut[..., 2]

    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    # Calculate hue
    hue = np.zeros_like(delta)
    mask_r = (cmax == r) & (delta > 0.001)
    mask_g = (cmax == g) & (delta > 0.001)
    mask_b = (cmax == b) & (delta > 0.001)

    hue[mask_r] = 60 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6)
    hue[mask_g] = 60 * (((b[mask_g] - r[mask_g]) / delta[mask_g]) + 2)
    hue[mask_b] = 60 * (((r[mask_b] - g[mask_b]) / delta[mask_b]) + 4)
    hue = hue % 360

    # Calculate saturation
    saturation = np.zeros_like(delta)
    nonzero = cmax > 0.001
    saturation[nonzero] = delta[nonzero] / cmax[nonzero]

    # Lightness
    lightness = (cmax + cmin) / 2

    # Create mask for target hue range with smooth falloff
    h_min, h_max = target_hue_range
    if h_min < h_max:
        in_range = (hue >= h_min) & (hue <= h_max)
        # Smooth edges
        center = (h_min + h_max) / 2
        width = (h_max - h_min) / 2
        dist = np.abs(hue - center)
        strength = np.clip(1.0 - (dist - width * 0.6) / (width * 0.4), 0, 1)
    else:
        # Wraps around 360
        in_range = (hue >= h_min) | (hue <= h_max)
        strength = np.where(in_range, 1.0, 0.0)

    # Also scale by existing saturation (don't affect grays)
    strength = strength * np.clip(saturation * 3, 0, 1)

    # Apply saturation shift
    if sat_shift != 0:
        new_sat = saturation * (1.0 + sat_shift)
        new_sat = np.clip(new_sat, 0, 1)
        # Rebuild RGB from HSL with new saturation
        sat_factor = np.where(saturation > 0.001, new_sat / saturation, 1.0)
        sat_factor = strength * sat_factor + (1 - strength) * 1.0
        luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        for c in range(3):
            result[..., c] = luminance + (lut[..., c] - luminance) * sat_factor

    # Apply luminance shift
    if lum_shift != 0:
        for c in range(3):
            result[..., c] = result[..., c] + strength * lum_shift * 0.15

    # Apply hue shift (simplified - rotate in RGB space)
    if hue_shift != 0:
        angle = hue_shift * np.pi / 180.0
        cos_a = np.cos(angle)
        sin_a = np.sin(angle)
        luminance = 0.2126 * result[..., 0] + 0.7152 * result[..., 1] + 0.0722 * result[..., 2]
        r_c = result[..., 0] - luminance
        g_c = result[..., 1] - luminance
        b_c = result[..., 2] - luminance
        # Simplified hue rotation
        nr = r_c * cos_a + g_c * sin_a * 0.5
        ng = g_c * cos_a - r_c * sin_a * 0.3 + b_c * sin_a * 0.3
        nb = b_c * cos_a - g_c * sin_a * 0.5
        result[..., 0] = result[..., 0] + strength * (nr - r_c) * 0.5
        result[..., 1] = result[..., 1] + strength * (ng - g_c) * 0.5
        result[..., 2] = result[..., 2] + strength * (nb - b_c) * 0.5

    return np.clip(result, 0, 1)


def split_tone(lut, shadow_rgb, highlight_rgb, balance=0.5):
    """Apply split toning - color shadows and highlights differently."""
    result = lut.copy()
    luminance = 0.2126 * lut[..., 0] + 0.7152 * lut[..., 1] + 0.0722 * lut[..., 2]

    shadow_mask = np.clip(1.0 - luminance * 2, 0, 1) ** 1.2
    highlight_mask = np.clip((luminance - 0.5) * 2, 0, 1) ** 1.2

    for c in range(3):
        result[..., c] = (lut[..., c]
                         + shadow_mask * (shadow_rgb[c] - 0.5) * 0.15
                         + highlight_mask * (highlight_rgb[c] - 0.5) * 0.15)

    return np.clip(result, 0, 1)


def write_cube(lut, filepath, title="LUT"):
    """Write 3D LUT to .cube file."""
    size = lut.shape[0]
    with open(filepath, 'w') as f:
        f.write(f'TITLE "{title}"\n')
        f.write(f'LUT_3D_SIZE {size}\n')
        f.write('DOMAIN_MIN 0.0 0.0 0.0\n')
        f.write('DOMAIN_MAX 1.0 1.0 1.0\n')
        f.write('\n')
        for b in range(size):
            for g in range(size):
                for r in range(size):
                    rgb = lut[b, g, r]
                    f.write(f'{rgb[0]:.6f} {rgb[1]:.6f} {rgb[2]:.6f}\n')


# ═══════════════════════════════════════════════════════════════
# VINTAGE - Retro/70s, warm earth tones, faded matte blacks
# ═══════════════════════════════════════════════════════════════
def generate_vintage():
    lut = identity_lut(LUT_SIZE)

    # Exposure +0.5
    lut = adjust_exposure(lut, 0.5)

    # Contrast -20
    lut = adjust_contrast(lut, -20)

    # Shadows +40
    lut = adjust_shadows(lut, 40)

    # Temperature +12 (warm/yellow)
    lut = adjust_temperature(lut, 12)

    # Tint +8 (toward pink)
    lut = adjust_tint(lut, 8)

    # Lift black point - matte/faded look (raise curve's bottom-left)
    lut = lift_blacks(lut, 0.06)

    # HLS Orange: Sat -10, Lum +20 (luminous skin)
    lut = hsl_adjust(lut, (15, 45), sat_shift=-0.10, lum_shift=0.20)

    # Split toning: warm shadows, golden highlights
    lut = split_tone(lut,
                     shadow_rgb=(0.55, 0.48, 0.42),    # warm brown shadows
                     highlight_rgb=(0.55, 0.52, 0.45))  # golden highlights

    # Final tone curve: slight S but with lifted blacks
    for c in range(3):
        lut[..., c] = apply_curve(lut[..., c], [
            (0.0, 0.05),   # Lifted blacks (matte)
            (0.15, 0.18),  # Slight shadow lift
            (0.5, 0.52),   # Midtones slightly bright
            (0.85, 0.87),
            (1.0, 0.98),   # Slightly rolled off highlights
        ])

    return lut


# ═══════════════════════════════════════════════════════════════
# MOOD - Editorial, dramatic, desaturated, killed greens/blues
# ═══════════════════════════════════════════════════════════════
def generate_mood():
    lut = identity_lut(LUT_SIZE)

    # Contrast +25
    lut = adjust_contrast(lut, 25)

    # Highlights -50
    lut = adjust_highlights(lut, -50)

    # Whites -15
    lut = adjust_whites(lut, -15)

    # Blacks -10 (deeper)
    lut = adjust_blacks(lut, -10)

    # Saturation -20
    lut = adjust_saturation(lut, -20)

    # Kill greens aggressively: Sat -80
    lut = hsl_adjust(lut, (75, 165), sat_shift=-0.80)

    # Kill blues: Sat -80
    lut = hsl_adjust(lut, (180, 260), sat_shift=-0.80)

    # Slight teal tone in shadows
    lut = split_tone(lut,
                     shadow_rgb=(0.45, 0.52, 0.55),    # cool teal shadows
                     highlight_rgb=(0.52, 0.50, 0.48))  # slightly warm highlights

    # Clarity +15 is a spatial filter (can't do in LUT), but we can
    # increase local contrast via S-curve in midtones
    for c in range(3):
        lut[..., c] = apply_curve(lut[..., c], [
            (0.0, 0.0),
            (0.20, 0.15),  # Deepen dark tones
            (0.40, 0.38),  # Steeper midtone transition
            (0.60, 0.63),  # Steeper midtone transition
            (0.80, 0.82),
            (1.0, 0.95),   # Rolled highlights
        ])

    return lut


# ═══════════════════════════════════════════════════════════════
# LUSH - Summer/tropical, warm, vibrant, cyan blues, orange skin
# ═══════════════════════════════════════════════════════════════
def generate_lush():
    lut = identity_lut(LUT_SIZE)

    # Temperature +15 (warm)
    lut = adjust_temperature(lut, 15)

    # Vibrance +20
    lut = adjust_vibrance(lut, 20)

    # Shadows +25
    lut = adjust_shadows(lut, 25)

    # HLS Blues: shift hue toward Cyan/Aqua, lower luminance
    # Blue range (200-260), shift toward cyan
    lut = hsl_adjust(lut, (200, 260), hue_shift=-25, lum_shift=-0.10)

    # HLS Yellows: shift hue toward Orange
    lut = hsl_adjust(lut, (40, 70), hue_shift=-15)

    # HLS Orange (skin): boost saturation slightly, lift luminance
    lut = hsl_adjust(lut, (15, 40), sat_shift=0.10, lum_shift=0.10)

    # Split toning: warm overall
    lut = split_tone(lut,
                     shadow_rgb=(0.52, 0.50, 0.45),    # warm shadows
                     highlight_rgb=(0.55, 0.52, 0.47))  # golden highlights

    # Gentle S-curve for pop
    for c in range(3):
        lut[..., c] = apply_curve(lut[..., c], [
            (0.0, 0.02),   # Slightly lifted blacks
            (0.25, 0.22),
            (0.50, 0.52),  # Slightly bright midtones
            (0.75, 0.78),
            (1.0, 1.0),
        ])

    # Vignette can't be in LUT (spatial), will be set in app

    return lut


# ═══════════════════════════════════════════════════════════════
# DREAM - Ethereal, soft, romantic, pastel, misty glow
# ═══════════════════════════════════════════════════════════════
def generate_dream():
    lut = identity_lut(LUT_SIZE)

    # Exposure +0.7
    lut = adjust_exposure(lut, 0.7)

    # Highlights -20
    lut = adjust_highlights(lut, -20)

    # Shadows +30
    lut = adjust_shadows(lut, 30)

    # Reduce contrast (Clarity negative = spatial, but LUT can reduce contrast)
    lut = adjust_contrast(lut, -30)

    # Slight desaturation for pastel look
    lut = adjust_saturation(lut, -10)

    # Pink/magenta tint
    lut = adjust_tint(lut, 10)

    # Lift blacks significantly for dreamy fade
    lut = lift_blacks(lut, 0.08)

    # HLS: boost pinks/magentas slightly
    lut = hsl_adjust(lut, (300, 360), sat_shift=0.15, lum_shift=0.05)
    lut = hsl_adjust(lut, (0, 20), sat_shift=0.10, lum_shift=0.05)

    # Soft pastel split toning
    lut = split_tone(lut,
                     shadow_rgb=(0.52, 0.48, 0.55),    # lavender shadows
                     highlight_rgb=(0.54, 0.52, 0.50))  # soft warm highlights

    # Gentle curve: very flat, compressed dynamic range for dreaminess
    for c in range(3):
        lut[..., c] = apply_curve(lut[..., c], [
            (0.0, 0.07),   # Heavily lifted blacks
            (0.20, 0.22),
            (0.50, 0.53),
            (0.80, 0.82),
            (1.0, 0.95),   # Rolled highlights
        ])

    return lut


# ═══════════════════════════════════════════════════════════════
# GOLDEN - Golden hour, warm sunlight, bronzed skin
# ═══════════════════════════════════════════════════════════════
def generate_golden():
    lut = identity_lut(LUT_SIZE)

    # Exposure +0.3 (bright but not blown)
    lut = adjust_exposure(lut, 0.3)

    # Temperature +18 (very warm, golden sunlight)
    lut = adjust_temperature(lut, 18)

    # Tint +5 (slight warmth)
    lut = adjust_tint(lut, 5)

    # Shadows +20 (open shadows)
    lut = adjust_shadows(lut, 20)

    # Highlights -30 (recover sky)
    lut = adjust_highlights(lut, -30)

    # Vibrance +15 (natural color boost)
    lut = adjust_vibrance(lut, 15)

    # HLS Orange (skin): boost sat slightly, lift luminance for golden skin
    lut = hsl_adjust(lut, (15, 45), sat_shift=0.15, lum_shift=0.15)

    # HLS Yellows: push toward warm orange
    lut = hsl_adjust(lut, (40, 70), hue_shift=-10, sat_shift=0.10)

    # Split toning: golden shadows, warm highlights
    lut = split_tone(lut,
                     shadow_rgb=(0.55, 0.50, 0.42),    # warm amber shadows
                     highlight_rgb=(0.56, 0.53, 0.45))  # golden highlights

    # Gentle S-curve with slight fade
    for c in range(3):
        lut[..., c] = apply_curve(lut[..., c], [
            (0.0, 0.03),   # Slight fade
            (0.25, 0.24),
            (0.50, 0.53),  # Bright midtones
            (0.75, 0.78),
            (1.0, 0.97),   # Slightly rolled highlights
        ])

    return lut


# ═══════════════════════════════════════════════════════════════
# Generate all
# ═══════════════════════════════════════════════════════════════
if __name__ == '__main__':
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    presets = {
        'ft_vintage': ('Vintage', generate_vintage),
        'ft_mood': ('Mood', generate_mood),
        'ft_lush': ('Lush', generate_lush),
        'ft_dream': ('Dream', generate_dream),
        'ft_golden': ('Golden Hour', generate_golden),
    }

    for filename, (title, gen_func) in presets.items():
        print(f'Generating {title}...')
        lut = gen_func()
        filepath = os.path.join(OUTPUT_DIR, f'{filename}.cube')
        write_cube(lut, filepath, title)
        print(f'  -> {filepath}')

    print('\nDone! 5 Featured LUTs generated.')
