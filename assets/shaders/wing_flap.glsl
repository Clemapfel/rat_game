#pragma glsl3

vec2 rotate_point(vec2 point, vec2 pivot, float angle_dg)
{
    float angle = angle_dg * (3.14159 / 180.0);

    float s = sin(angle);
    float c = cos(angle);

    point -= pivot;
    point.x = point.x * c - point.y * s;
    point.y = point.x * s + point.y * c;
    point += pivot;

    return point;
}

float f(float x, float t)
{
    return 1 * sqrt(exp(-1 * t * x)) - 1;
}

float g(float x, float t)
{

    return -1 * sqrt(exp(t * x)) + 1;
}

// ###########

uniform float _time;

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    vec2 pos = vertex_position / screen_size;
    float time = _time;

    pos -= vec2(0.5);
    pos *= 10;

    pos.y = rotate_point(pos, vec2(0, 0), mod((time * 360 / 10), 360)).y;

    float t = sin(time) * 10;
    float x = pos.x;

    float value = 0;
    if (t < 0)
        value = x > 0 ? f(x, t) : g(x, t);
    else if (t > 0)
        value = x > 0 ? g(x, t) : f(x, t);

    bool line = abs(pos.y - value) < 0.01;

    if (line)
        return vec4(vec3(1), 1);
    else
        return vec4(vec3(0), 1);


}