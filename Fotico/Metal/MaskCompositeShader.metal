#include <metal_stdlib>
using namespace metal;

/// Composites two images using a grayscale mask.
/// Where mask is white (1.0) → show effect image.
/// Where mask is black (0.0) → show original image.
kernel void maskComposite(
    texture2d<float, access::read> original   [[texture(0)]],
    texture2d<float, access::read> effect     [[texture(1)]],
    texture2d<float, access::read> mask       [[texture(2)]],
    texture2d<float, access::write> output    [[texture(3)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) return;

    float2 maskUV = float2(gid) / float2(output.get_width(), output.get_height());
    uint2 maskPos = uint2(maskUV * float2(mask.get_width(), mask.get_height()));
    maskPos = min(maskPos, uint2(mask.get_width() - 1, mask.get_height() - 1));

    float4 origColor = original.read(gid);
    float4 effectColor = effect.read(gid);
    float maskValue = mask.read(maskPos).r;

    output.write(mix(origColor, effectColor, maskValue), gid);
}
