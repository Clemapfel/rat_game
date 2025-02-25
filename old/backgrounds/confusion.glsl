// src: https://archives.bulbagarden.net/media/upload/0/09/Confusion_III.png

#define PI 3.1415926535897932384626433832795


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

vec2 rotate(vec2 point, float angle) {
    return vec2(
        point.x * cos(angle) - point.y * sin(angle),
        point.x * sin(angle) + point.y * cos(angle)
    );
}

vec3 lch_to_rgb(vec3 lch) {
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
}

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

float sine_wave(float x)
{
    return (sin(x) + 1) / 2;
}

float gaussian(float x, float ramp)
{
    // e^{-\frac{4\pi}{3}\left(r\cdot\left(x-c\right)\right)^{2}}
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 uv = texture_coords.xy;
    uv /= 1.2;
    
    float time = elapsed / 2;
    
    uv -= vec2(0.5);
    const float angle = PI / 2.5;
    uv = rotate(uv, angle + time / 100);
    uv += vec2(0.5);

    const float frequency = 40;

    uv.y += sin(uv.x * 20) / 100;
    float value = sin(uv.y * frequency + time);

    float magnitude = fwidth(value) * 1.2;
    uv -= vec2(0.5);
    uv = rotate(uv, angle + PI / 4 + sin(time) * 0.1);
    uv += vec2(0.5);

    uv.y += sin(uv.x * 20) / 50;
    value = value + sin(uv.y * frequency + time * 3);

    float rng = gradient_noise(vec3(vertex_position / 200, time)) / 8;
    float hue = fract(value * magnitude * (1 + 2 * sine_wave(time + rng)) + time / 10) + 0.3;

    vec3 color = lch_to_rgb(vec3(0.1 + 0.7 * gaussian(texture_coords.y * 2 - 1, 0.5), 1, hue));
    return vec4(color, 1);
}