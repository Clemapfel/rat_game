/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

float random_1d(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
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

vec3 lch_to_rgb(vec3 lch) {
    // Scale the input values
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    // Convert LCH to LAB
    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    // Convert LAB to XYZ
    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    // Convert XYZ to RGB
    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    // Apply gamma correction
    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
}

#pragma language glsl4

struct InstanceData {
    vec2 center;
    float radius;
    float rotation;
    float hue;
};

uniform uint n_instances;
layout(std430) readonly buffer instance_data_buffer {
    InstanceData instance_data[]; // size: n_instances
};

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

#define PI 3.1415926535897932384626433832795
float gaussian(float x, float ramp)
{
    return exp(-1 * pow((4.4 * PI / 3) * (2 * ramp * x - 1), 2));
}

float fractal_noise(vec3 p, int octaves, float persistence, float lacunarity) {
    float amplitude = 1.0;
    float frequency = 1.0;
    float noise = 0.0;
    float maxAmplitude = 0.0;

    for (int i = 0; i < octaves; i++) {
        noise += gradient_noise(p * frequency) * amplitude;
        maxAmplitude += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return noise / maxAmplitude;
}

#ifdef VERTEX

varying vec4 color;
uniform float elapsed;

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    InstanceData data = instance_data[instance_id];

    float time = elapsed / 5;

    float omit_first = distance(vertex_position.xy, vec2(0)); // 0 for center, 1 for everything else
    float angle = atan(vertex_position.y, vertex_position.x) + data.rotation + elapsed;
    const float scale = 5;

    vec2 position = vec2(data.center.xy / love_ScreenSize.xy * scale);

    // Use fractal noise with octaves
    int octaves = 2; // Number of octaves
    float persistence = 0.5; // Amplitude reduction per octave
    float lacunarity = 2.0; // Frequency increase per octave
    float radius = fractal_noise(vec3(position, time), octaves, persistence, lacunarity);

    radius = clamp(radius * 1.1, 0, 1);

    vertex_position.xy = translate_point_by_angle(data.center, 100 * radius * omit_first, angle);

    color.rgb = lch_to_rgb(vec3(0.8, 1, data.hue));
    color.a = 1;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 color;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    return color * vertex_color * Texel(image, texture_coords);
}
#endif