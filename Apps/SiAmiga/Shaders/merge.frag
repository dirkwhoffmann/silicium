#version 440

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float longFrameScale;
    float shortFrameScale;
    float texHeight;
    float xrayOverlay;      // 1.0 if the xray texture is blended in
    float xrayFgWeight;     // Weight of the picture under an xray pixel
    float xrayBgWeight;     // Dimming of the picture where there is no xray pixel
} ubuf;

layout(binding = 1) uniform sampler2D longFrame;
layout(binding = 2) uniform sampler2D shortFrame;
layout(binding = 3) uniform sampler2D longXray;
layout(binding = 4) uniform sampler2D shortXray;

void main()
{
    // Weave the two half-frames back together: in field space every source
    // line covers two lines, the long frame owning the even ones and the
    // short frame the odd ones. Same field ordering merge1X4Y writes into
    // vAmiga's 4x-height merge texture (GUI/Metal/Shaders.metal), which
    // spends two of its four lines per group on each field.
    float fieldRow = floor(vTexCoord.y * 2.0 * ubuf.texHeight);
    float srcRow = floor(fieldRow * 0.5);
    vec2 uv = vec2(vTexCoord.x, (srcRow + 0.5) / ubuf.texHeight);

    vec4 texel;
    vec4 xray;
    float scale;

    if (mod(fieldRow, 2.0) < 1.0) {

        texel = texture(longFrame, uv);
        xray = texture(longXray, uv);
        scale = ubuf.longFrameScale;

    } else {

        texel = texture(shortFrame, uv);
        xray = texture(shortXray, uv);
        scale = ubuf.shortFrameScale;
    }

    /* Blend the xray texture into the picture. Same arithmetic as
     * PixelEngine::mergeXray() in the core, which does this on the CPU for
     * hosts that cannot: a black xray pixel means that there is no effect
     * at this place.
     */
    if (ubuf.xrayOverlay > 0.5) {

        if (xray.rgb != vec3(0.0)) {

            texel.rgb = ubuf.xrayFgWeight != 0.0 ? mix(xray.rgb, texel.rgb, ubuf.xrayFgWeight)
                                                  : xray.rgb;

        } else if (ubuf.xrayBgWeight != 0.0) {

            texel.rgb *= 1.0 - ubuf.xrayBgWeight;
        }
    }

    // The emulator texture is opaque, so alpha only ever carries the item's
    // own opacity (premultiplied, as the scene graph expects).
    fragColor = vec4(texel.rgb * scale, 1.0) * ubuf.qt_Opacity;
}
