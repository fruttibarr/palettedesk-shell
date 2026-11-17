#version 300 es
// Vibrant: pushes saturation up by 35%.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    float g = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(clamp(mix(vec3(g), c.rgb, 1.35), 0.0, 1.0), c.a);
}
