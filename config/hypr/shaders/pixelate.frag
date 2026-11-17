#version 300 es
// Pixelate: the whole screen in chunky 3x3 blocks.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 size = vec2(textureSize(tex, 0));
    vec2 uv = (floor(v_texcoord * size / 3.0) + 0.5) * 3.0 / size;
    fragColor = vec4(texture(tex, uv).rgb, 1.0);
}
