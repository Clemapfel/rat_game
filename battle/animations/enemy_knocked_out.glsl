#ifdef PIXEL

uniform float value;
uniform vec2 position;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    float normalize_factor = love_ScreenSize.y / love_ScreenSize.x;
    vec2 normalized = (texture_coords + vec2(0.5, 0.5) - position / love_ScreenSize.xy) * vec2(1, normalize_factor);
    normalized.y += (1 - normalize_factor) / 2;

    float fraction = 1 - clamp(distance(normalized, vec2(0.5)) * 2 + (value * 2 - 1), 0, 1);
    return Texel(image, texture_coords) * fraction * vertex_color;
}
#endif