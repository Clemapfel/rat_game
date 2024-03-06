vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

uniform Image _coefficients;
uniform Image _energies;

uniform float _index;
uniform float _max_index;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float playhead = float(_index) / float(_max_index);
    float scale = float(100) / _max_index;
    texture_coords.x = texture_coords.x * scale - (1 * scale - playhead);

    float coefficient = Texel(_coefficients, texture_coords).x;
    float energy = Texel(_energies, texture_coords).x;

    float value = coefficient;
    return vec4(hsv_to_rgb(vec3(value, 1, value)), 1);
}