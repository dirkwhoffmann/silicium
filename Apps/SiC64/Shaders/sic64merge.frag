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
     * DmaDebugger::computeOverlay() in the core, which does this on the CPU
     * for hosts that cannot: a black xray pixel means that there is no effect
     * at this place.
     */
    if (ubuf.xrayOverlay > 0.5) {

        vec3 dma = texture(xray, vTexCoord).rgb;
        bool effect = dma != vec3(0.0);

        if (ubuf.xrayStyle < 0.5) {

            // Foreground layer
            if (effect) color = mix(color, dma, ubuf.xrayWeight);

        } else if (ubuf.xrayStyle < 1.5) {

            // Background layer
            color = effect ? dma : color * (1.0 - ubuf.xrayWeight);

        } else {

            // Mixed layers
            color = mix(dma, color, ubuf.xrayWeight);
        }
    }

    // The emulator texture is opaque, so alpha only ever carries the item's
    // own opacity (premultiplied, as the scene graph expects).
    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
