uniform float gamma;
float gamma_inverse = 1.0 / gamma;

vec4 effect(vec4 vertex_color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 color = Texel(tex, texture_coords);
    vec3 color_corrected = pow(color.rgb, vec3(gamma_inverse));
    return vec4(color_corrected, color.a);
}