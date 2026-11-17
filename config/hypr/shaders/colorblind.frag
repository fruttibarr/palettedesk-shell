#version 300 es
// Color-blind aid (red-green): shifts the color information a deuteranope cannot see into channels they can.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

// Machado et al. deuteranopia simulation, then the usual error-shift ("daltonize") correction.
const mat3 SIM = transpose(mat3(0.367322, 0.860646, -0.227968,
                                0.280085, 0.672501,  0.047413,
                               -0.011820, 0.042940,  0.968881));
const mat3 SHIFT = transpose(mat3(0.0, 0.0, 0.0,
                                  0.7, 1.0, 0.0,
                                  0.7, 0.0, 1.0));
void main() {
    vec4 c = texture(tex, v_texcoord);
    vec3 err = c.rgb - SIM * c.rgb;
    fragColor = vec4(clamp(c.rgb + SHIFT * err, 0.0, 1.0), c.a);
}
