#pragma language glsl3

uniform vec4 _left_color;
uniform vec4 _right_color;

float shape(float x, float a)
{
    //float a = 0.045;
    return a * exp(log(1.0 / a + 1.0) * x) - a;
}

vec4 effect(vec4 _, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 screen_size = love_ScreenSize.xy;
    vec4 color = mix(_left_color, _right_color, shape(smoothstep(0, 1, texture_coords.x), 0.6));
    return color;
}