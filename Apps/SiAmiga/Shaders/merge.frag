#version 440

layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float longFrameScale;
    float shortFrameScale;
    float texHeight;
} ubuf;

layout(binding = 1) uniform sampler2D longFrame;
layout(binding = 2) uniform sampler2D shortFrame;

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
    float scale;

    if (mod(fieldRow, 2.0) < 1.0) {

        texel = texture(longFrame, uv);
        scale = ubuf.longFrameScale;

    } else {

        texel = texture(shortFrame, uv);
        scale = ubuf.shortFrameScale;
    }

    // The emulator texture is opaque, so alpha only ever carries the item's
    // own opacity (premultiplied, as the scene graph expects).
    fragColor = vec4(texel.rgb * scale, 1.0) * ubuf.qt_Opacity;
}
