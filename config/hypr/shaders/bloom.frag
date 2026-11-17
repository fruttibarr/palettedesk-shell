#version 300 es
// Soft bloom: bright areas glow into their surroundings (cheap 12-tap blur of the highlights).
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    vec2 px = 1.0 / vec2(textureSize(tex, 0));
    vec3 glow = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 0.5236;
        for (int r = 1; r <= 2; r++) {
            vec2 o = vec2(cos(a), sin(a)) * px * float(r) * 6.0;
            vec3 s = texture(tex, v_texcoord + o).rgb;
            glow += max(s - 0.55, 0.0);
        }
    }
    fragColor = vec4(c.rgb + glow / 24.0 * 1.8, c.a);
}
