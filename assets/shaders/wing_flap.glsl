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

    float t = sin(time) * 10;

    bool a = abs(pos.y - f(pos.x, t)) < 0.01 || abs(pos.y - g(pos.x, t)) < 0.01;

    pos = rotate_point(pos, vec2(0), t * 2);
    bool b = abs(pos.y - f(pos.x, t)) < 0.01 || abs(pos.y - g(pos.x, t)) < 0.01;

    if (a || b)
        return vec4(vec3(1), 1);
    else
        return vec4(vec3(0), 1);
}