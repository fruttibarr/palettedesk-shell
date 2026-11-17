#version 300 es
// Posterize: limits every channel to a few levels for a flat, printed look.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    float n = 6.0;
    fragColor = vec4(floor(c.rgb * n + 0.5) / n, c.a);
}
