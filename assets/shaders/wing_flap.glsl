#pragma glsl3

uniform float _time;

float flap(float x, float t)
{
    float prefix = t > 0 ? 1 : -1;
    x = prefix * x;
    if (t > 0)
        return 1 * sqrt(exp(-1 * t * x)) - 1;
    else if (t < 0)
        return -1 * sqrt(exp(t * x)) + 1;
    else
        return 0.f;

    return 1 * sqrt(exp(-1 * t * x)) - 1;
}

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    vec2 pos = vertex_position / screen_size;
    float time = _time;

    pos -= vec2(0.5);
    pos *= 10;

    float x = pos.x;
    float y = pos.y;
    float t = sin(time) * 10;

    if (abs(y - flap(x, t)) < 0.01)
        return vec4(vec3(1), 1);
    else
        return vec4(vec3(0), 1);
}