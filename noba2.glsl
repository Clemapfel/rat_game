uniform float time;

#define PI 3.1415926535897932384626433832795

uniform vec3 color_dark = vec3(0.1, 0, 0.1);
uniform vec3 color_light = vec3(0.13, 0, 0.13) * 2;


vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen_cords)
{
    float eps = 0.02;
    float stretch = (1 + 2 * eps) * sin(time);
    float line_width = 0.5;

    const float n_lines = 5;
    uv *= n_lines * 2;

    //uv.x += time;
    float line_x = uv.y;
    float direction = (mod(floor(uv.x / 2), 2.0)) * 2.0 - 1.0;
    float line_y = stretch * (sin(line_x + direction * time) / 2) + 1;

    float line = smoothstep(line_width - eps, line_width + eps, distance(fract(uv.x / 2) * 2, line_y));

    return vec4(mix(color_dark, color_light, line), 1);
}