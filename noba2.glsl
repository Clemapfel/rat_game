uniform float time;

#define PI 3.1415926535897932384626433832795

uniform vec3 color_dark = vec3(0.1, 0, 0.1);
uniform vec3 color_light = vec3(0.13, 0, 0.13) ;


/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

/// @brief gradient noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/gnoise.glsl
float gradient_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    return mix( mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

float circle_wave(in vec2 position, in float theta_base, in float radius, float offset) {

    // adapted from: https://www.shadertoy.com/view/stGyzt

    theta_base = PI * max(theta_base, 0.0001);
    vec2 circle_origin = radius * vec2(sin(theta_base), cos(theta_base));

    position.x = abs(mod(position.x, circle_origin.x * 4.0) - circle_origin.x * 2.0);
    vec2 position1 = position;
    vec2 position2 = vec2(abs(position.x - 2.0 * circle_origin.x), -position.y + 2.0 * circle_origin.y);
    float distance1 = ((circle_origin.y * position1.x > circle_origin.x * position1.y) ? length(position1 - circle_origin) : abs(length(position1) - radius));
    float distance2 = ((circle_origin.y * position2.x > circle_origin.x * position2.y) ? length(position2 - circle_origin) : abs(length(position2) - radius));
    return min(distance1, distance2);
}

float sine_wave(float x, float frequency) {
    return (sin(2.0 * PI * x * frequency - PI / 2.0) + 1.0) * 0.5;
}

vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen_cords) {

    float eps = 0.002;
    float line_width = 0.058;
    int n_lines = 4;
    float offset = sin(time / 3) * 0.1;
    float amplitude = 0.3;
    float frequency = 0.1;

    uv *= 1;
    uv = rotate(uv, 0.1 * PI);
    uv.x += time / 40.0;

    float repeat_index = floor(uv.x * n_lines);
    float y_offset = time / 30;
    if (mod(repeat_index, 2.0) == 1.0) {
        uv.x = 1 - uv.x;
        //uv.x += y_offset;
    }
    else {
        //uv.x += y_offset;
    }

    uv.x = fract(uv.x * n_lines) / n_lines;
    uv.x -= line_width * 1.1;

    float value = smoothstep(line_width - eps, line_width + eps, circle_wave(uv.yx, amplitude, frequency, sin(time)));
    return vec4(mix(color_dark, color_light, value), 1);
}