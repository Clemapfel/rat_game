#pragma language glsl3

uniform Image _spectrum;
uniform vec2 _spectrum_size;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    texture_coords.xy = texture_coords.yx;
    vec4 value = Texel(_spectrum, vec2(texture_coords.x, texture_coords.y));
    return vec4(value.xxx, 1);
}