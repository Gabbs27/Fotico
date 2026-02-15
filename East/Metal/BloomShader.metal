#include <metal_stdlib>
using namespace metal;

// Extract bright areas above threshold
kernel void bloomThresholdKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &threshold [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 color = inTexture.read(gid);
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    float contribution = smoothstep(threshold, threshold + 0.1, luminance);
    float3 result = color.rgb * contribution;

    outTexture.write(float4(result, color.a), gid);
}

// Simple box blur pass (horizontal or vertical based on direction)
kernel void bloomBlurKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant int &blurRadius [[buffer(0)]],
    constant int &isHorizontal [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 sum = float4(0.0);
    float weightSum = 0.0;

    for (int i = -blurRadius; i <= blurRadius; i++) {
        int2 offset = isHorizontal != 0 ? int2(i, 0) : int2(0, i);
        int2 samplePos = int2(gid) + offset;

        // Clamp to texture bounds
        samplePos.x = clamp(samplePos.x, 0, int(inTexture.get_width()) - 1);
        samplePos.y = clamp(samplePos.y, 0, int(inTexture.get_height()) - 1);

        // Gaussian-like weight
        float weight = exp(-float(i * i) / float(2 * blurRadius * blurRadius + 1));
        sum += inTexture.read(uint2(samplePos)) * weight;
        weightSum += weight;
    }

    outTexture.write(sum / weightSum, gid);
}

// Additive blend of bloom with original
kernel void bloomCompositeKernel(
    texture2d<float, access::read> originalTexture [[texture(0)]],
    texture2d<float, access::read> bloomTexture [[texture(1)]],
    texture2d<float, access::write> outTexture [[texture(2)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= originalTexture.get_width() || gid.y >= originalTexture.get_height()) return;

    float4 original = originalTexture.read(gid);
    float4 bloom = bloomTexture.read(gid);

    float3 result = original.rgb + bloom.rgb * intensity;
    result = clamp(result, 0.0, 1.0);

    outTexture.write(float4(result, original.a), gid);
}
