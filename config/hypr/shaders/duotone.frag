#version 300 es
// Duotone: shadows go deep indigo, highlights go warm peach.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 lo = vec3(0.06, 0.05, 0.22), hi = vec3(1.0, 0.82, 0.68);
    fragColor = vec4(mix(lo, hi, smoothstep(0.0, 1.0, l)), c.a);
}
