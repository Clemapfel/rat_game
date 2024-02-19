#pragma language glsl3

uniform Image _spectrum;
uniform vec2 _spectrum_size;
uniform float _energy;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    texture_coords.xy = texture_coords.yx;
    vec4 value = Texel(_spectrum, vec2(texture_coords.x, 1));
    return vec4(vec3(_energy), 1);
}