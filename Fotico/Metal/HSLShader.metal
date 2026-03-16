#include <metal_stdlib>
using namespace metal;

struct HSLParams {
    float hueCenters[8];
    float hueShifts[8];
    float satShifts[8];
    float lumShifts[8];
    uint activeCount;
};

float3 rgbToHsl(float3 rgb) {
    float maxC = max(max(rgb.r, rgb.g), rgb.b);
    float minC = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxC - minC;

    float h = 0.0;
    float s = 0.0;
    float l = (maxC + minC) * 0.5;

    if (delta > 0.0001) {
        s = l < 0.5 ? delta / (maxC + minC) : delta / (2.0 - maxC - minC);

        if (maxC == rgb.r) {
            h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
        } else if (maxC == rgb.g) {
            h = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            h = (rgb.r - rgb.g) / delta + 4.0;
        }
        h /= 6.0;
    }

    return float3(h, s, l);
}

float3 hslToRgb(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (s < 0.0001) {
        return float3(l, l, l);
    }

    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;

    float tr = h + 1.0/3.0;
    float tg = h;
    float tb = h - 1.0/3.0;

    // hue2rgb inline for r
    if (tr < 0.0) tr += 1.0;
    if (tr > 1.0) tr -= 1.0;
    float r = (tr < 1.0/6.0) ? p + (q - p) * 6.0 * tr :
              (tr < 1.0/2.0) ? q :
              (tr < 2.0/3.0) ? p + (q - p) * (2.0/3.0 - tr) * 6.0 : p;

    // hue2rgb inline for g
    if (tg < 0.0) tg += 1.0;
    if (tg > 1.0) tg -= 1.0;
    float g = (tg < 1.0/6.0) ? p + (q - p) * 6.0 * tg :
              (tg < 1.0/2.0) ? q :
              (tg < 2.0/3.0) ? p + (q - p) * (2.0/3.0 - tg) * 6.0 : p;

    // hue2rgb inline for b
    if (tb < 0.0) tb += 1.0;
    if (tb > 1.0) tb -= 1.0;
    float b = (tb < 1.0/6.0) ? p + (q - p) * 6.0 * tb :
              (tb < 1.0/2.0) ? q :
              (tb < 2.0/3.0) ? p + (q - p) * (2.0/3.0 - tb) * 6.0 : p;

    return float3(r, g, b);
}

float hueWeight(float pixelHue, float targetHue, float width) {
    float dist = abs(pixelHue - targetHue);
    dist = min(dist, 1.0 - dist);
    return smoothstep(width, 0.0, dist);
}

kernel void hslAdjustKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant HSLParams &params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float4 pixel = inTexture.read(gid);
    float3 hsl = rgbToHsl(pixel.rgb);

    float hueWidth = 0.06;

    for (uint i = 0; i < params.activeCount; i++) {
        float w = hueWeight(hsl.x, params.hueCenters[i], hueWidth);
        if (w > 0.001) {
            hsl.x += params.hueShifts[i] * w;
            hsl.y = clamp(hsl.y + params.satShifts[i] * w, 0.0, 1.0);
            hsl.z = clamp(hsl.z + params.lumShifts[i] * w, 0.0, 1.0);
        }
    }

    hsl.x = fract(hsl.x);

    float3 rgb = hslToRgb(hsl);
    outTexture.write(float4(rgb, pixel.a), gid);
}
