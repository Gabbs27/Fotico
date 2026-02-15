#include <metal_stdlib>
using namespace metal;

kernel void lightLeakKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &leakColor [[buffer(0)]],
    constant float2 &center [[buffer(1)]],
    constant float &radius [[buffer(2)]],
    constant float &opacity [[buffer(3)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 color = inTexture.read(gid);

    float2 uv = float2(gid);
    float dist = distance(uv, center);

    // Soft radial falloff
    float falloff = 1.0 - smoothstep(0.0, radius, dist);
    falloff = pow(falloff, 1.5); // Softer falloff curve

    // Screen blend mode: result = 1 - (1 - base) * (1 - blend)
    float3 leak = leakColor.rgb * falloff * opacity;
    float3 result = 1.0 - (1.0 - color.rgb) * (1.0 - leak);

    outTexture.write(float4(result, color.a), gid);
}
