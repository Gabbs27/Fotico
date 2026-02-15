#include <metal_stdlib>
using namespace metal;

// Simple hash function for procedural noise
float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Value noise
float valueNoise(float2 uv) {
    float2 i = floor(uv);
    float2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

kernel void grainKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    constant float &grainSize [[buffer(1)]],
    constant float &seed [[buffer(2)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 color = inTexture.read(gid);

    // Generate grain noise
    float2 uv = float2(gid) / grainSize;
    uv += float2(seed * 127.1, seed * 311.7);

    float noise = valueNoise(uv * 8.0);
    noise = (noise - 0.5) * 2.0; // Center around 0

    // Luminance-weighted grain (more visible in midtones, like real film)
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    float midtoneMask = 1.0 - abs(luminance - 0.5) * 2.0;
    midtoneMask = max(midtoneMask, 0.3); // Minimum grain everywhere

    float grainAmount = noise * intensity * midtoneMask;

    float3 result = color.rgb + grainAmount;
    result = clamp(result, 0.0, 1.0);

    outTexture.write(float4(result, color.a), gid);
}
