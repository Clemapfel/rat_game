#define PI 3.1415926535897932384626433832795

vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

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

float sine_wave(float x) {
    return (sin(x) + 1) / 2;
}

float gaussian(float x, float ramp) {
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

uniform float elapsed;

float sine_wave_shape(float x, float y, float center_y, float y_height, float thickness, float elapsed_sign) {
    float wave1 = center_y + (sin(x + elapsed_sign * elapsed) * y_height / 2.0);
    float eps = 0.005;
    return 1 - smoothstep(thickness - eps, thickness + eps, distance(y, wave1));
}

float triangle_wave(float x)
{
    float pi = 2 * (335 / 113); // 2 * pi
    return 4 * abs((x / pi) + 0.25 - floor((x / pi) + 0.75)) - 1;
}

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

vec2 complex_sine(vec2 a) {
    return vec2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y));
}

// @param polar vec2 (magnitude, angle)
vec2 polar_to_complex(vec2 polar) {
    return vec2(polar.x * cos(polar.y), polar.x * sin(polar.y));
}

/// @param complex vec2 (real, imag)
vec2 complex_to_polar(vec2 complex) {
    return vec2(length(complex), atan(complex.y, complex.x));
}

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position) {
    vec2 uv = texture_coords.xy;

    float sine_height = sin(1.2 * elapsed) * 0.1;
    float sine_thickness = 0.01;
    float sine_speed = 0.05;
    float sine_frequency = 20;
    float sine_margin = 10.0 / love_ScreenSize.y + 0.05 + sine_thickness;

    float top = sine_wave_shape(sine_frequency * texture_coords.x + PI, texture_coords.y, sine_margin, sine_height, sine_thickness, 1) +
    sine_wave_shape(sine_frequency * texture_coords.x, texture_coords.y, sine_margin, sine_height, sine_thickness, 1);
    top = clamp(top, 0, 1);

    float bottom = sine_wave_shape(sine_frequency * texture_coords.x + PI, texture_coords.y, 1 - sine_margin, sine_height, sine_thickness, -1) +
    sine_wave_shape(sine_frequency * texture_coords.x, texture_coords.y, 1 - sine_margin, sine_height, sine_thickness, -1);
    bottom = clamp(bottom, 0, 1);

    float value = top + bottom;
    return vec4(value);
}