#version 300 es
// Retro CRT: scanlines, a little RGB mask and a soft vignette.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    float scan = 0.88 + 0.12 * sin(gl_FragCoord.y * 3.14159);
    float mask = 0.96 + 0.04 * sin(gl_FragCoord.x * 2.0944);
    vec2 d = v_texcoord - 0.5;
    float vig = 1.0 - dot(d, d) * 0.9;
    fragColor = vec4(c.rgb * scan * mask * vig * 1.06, c.a);
}
