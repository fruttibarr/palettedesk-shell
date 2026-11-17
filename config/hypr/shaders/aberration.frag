#version 300 es
// Chromatic aberration: red and blue fringe apart towards the screen edges, like a cheap lens.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 d = v_texcoord - 0.5;
    vec2 o = d * dot(d, d) * 0.018;
    float r = texture(tex, v_texcoord + o).r;
    vec4 g = texture(tex, v_texcoord);
    float b = texture(tex, v_texcoord - o).b;
    fragColor = vec4(r, g.g, b, g.a);
}
