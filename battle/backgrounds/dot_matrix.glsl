#ifdef PIXEL

uniform float radius;
uniform float time;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 pos = texture_coords;
    vec2 center = vec2(0.5);
    float r = radius / max(love_ScreenSize.x, love_ScreenSize.y);

    pos.x *= love_ScreenSize.x / love_ScreenSize.y;
    center.x *= love_ScreenSize.x / love_ScreenSize.y;

    float value = distance(pos, center) / r;
    return vec4(vec3(value), 1);
}

#endif
