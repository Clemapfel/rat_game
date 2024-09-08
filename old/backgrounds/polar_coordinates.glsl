#define PI 3.1415926535897932384626433832795

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    const vec2 center = vec2(0.5);
    vec2 pos = texture_coords.xy - center;
    pos.y *= love_ScreenSize.y / love_ScreenSize.x;

    pos.x = pos.x + sin(elapsed);

    vec2 polar = vec2(length(pos.xy), atan(pos.y, pos.x));
    pos = translate_point_by_angle(vec2(0.5), polar.x / 2, polar.y);

    float value = sin(15 * polar.x - elapsed) + sin(pos.y);
    return vec4(vec3(value), 1);
}

#endif
