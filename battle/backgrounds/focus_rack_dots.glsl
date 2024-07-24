#define PI 3.1415926535897932384626433832795

#ifdef PIXEL

uniform int mode;
uniform float focus;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float radius = 0.2;
    float border = focus;
    vec2 center = vec2(0.5, 0.5);
    vec2 pos = texture_coords;
    float x_normalization_factor = love_ScreenSize.y / love_ScreenSize.x;
    pos.x /= x_normalization_factor;
    center.x /= x_normalization_factor;

    float value = 1 - smoothstep(radius - border, radius + border, distance(pos, center));
    return vec4(vec3(value), 1);
}

#endif
