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

// Function to generate a periodic circular wave with every second period flipped
float circular_wave(float x) {
    return sin(acos(2 * x));
}

vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen_cords)
{
    float eps = 0.02;
    float stretch = (1 + 2 * eps) * sin(time);
    float line_width = 0.8;

    const float n_lines = 5;
    uv *= n_lines * 2;
    //uv += time / 1.5;

    //uv.x += time;
    float line_x = uv.y;
    float direction = (mod(floor(uv.x / 2), 2.0)) * 2.0 - 1.0;
    line_x += (direction > 0 ? 1 : 0) * PI;

    float line_y = stretch * (circular_wave(line_x) / 2) + 1;

    float line = smoothstep(line_width - eps, line_width + eps, distance(fract(uv.x / 2) * 2, line_y));

    return vec4(smoothstep(-0.05, 0.05, distance(fract(uv.y), circular_wave(uv.x))));
  //  return vec4(mix(color_dark, color_light, line), 1);
}