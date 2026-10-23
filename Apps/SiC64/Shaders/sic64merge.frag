#version 440

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float xrayOverlay;      // 1.0 if the xray texture is blended in
    float xrayStyle;        // 0 = foreground layer, 1 = background layer, 2 = mixed layers
    float xrayWeight;       // The opacity of the overlay
} ubuf;

layout(binding = 1) uniform sampler2D picture;
layout(binding = 2) uniform sampler2D xray;

void main()
{
    vec3 color = texture(picture, vTexCoord).rgb;

    /* Blend the xray texture into the picture. Same arithmetic as
     * XRay::computeOverlay() in the core, which does this on the CPU
     * for hosts that cannot: a non-black xray pixel is an effect pixel that
     * is mixed with the picture, a black one dims it.
     */
    if (ubuf.xrayOverlay > 0.5) {

        float opacity = ubuf.xrayWeight;
        float fg = ubuf.xrayStyle < 0.5 ? 1.0 - opacity       // Foreground layer
                 : ubuf.xrayStyle < 1.5 ? 0.0                 // Background layer
                 :                        1.0 - opacity;      // Mixed layers
        float bg = ubuf.xrayStyle < 0.5 ? 0.0
                 : ubuf.xrayStyle < 1.5 ? 1.0 - opacity
                 :                        opacity;

        vec3 dma = texture(xray, vTexCoord).rgb;

        if (dma != vec3(0.0)) {
            color = fg != 0.0 ? mix(dma, color, fg) : dma;
        } else if (bg != 0.0) {
            color *= 1.0 - bg;
        }
    }

    // The emulator texture is opaque, so alpha only ever carries the item's
    // own opacity (premultiplied, as the scene graph expects).
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
