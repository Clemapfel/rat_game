#pragma language glsl3

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

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
    dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2
    const float K2 = 0.211324865; // (3-sqrt(3))/6

    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = step(a.yx, a.xy);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;

    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)),
    dot(b, hash(i + o)),
    dot(c, hash(i + 1.0)));

    return dot(n, vec3(70.0));
}

// ###############################

#define PI 3.14159265359

const float rainbow_width = 150;

uniform float shake_offset = 1;
const float shake_speed = 10; // steps per second

const float wave_period = 10;
const float wave_offset = 5;
const float wave_speed = 4;

uniform int n_visible_characters;
uniform bool is_effect_rainbow;
uniform bool is_effect_wave;
uniform bool is_effect_shake;
uniform float elapsed;

#ifdef VERTEX

flat varying int letter_index;

vec4 position(mat4 transform, vec4 vertex_position)
{
    letter_index = gl_VertexID / 4;

    vec2 position = vertex_position.xy;
    float time = elapsed;

    if (is_effect_shake)
    {
        float i_offset = round(time * shake_speed);
        position.x += noise(position * vec2(i_offset)) * shake_offset;
        position.y += noise(position * vec2(i_offset + 1234.5678)) * shake_offset;
    }

    if (is_effect_wave)
    {
        float x = ((time * wave_speed) + letter_index);
        position.y += sin((x * 2 * PI) / wave_period) * wave_offset;
    }

    vertex_position.xy = position;
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

flat varying int letter_index;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    if (letter_index >= n_visible_characters)
        discard;

    vec4 color = Texel(image, texture_coords) * vertex_color;
    if (is_effect_rainbow)  {
        float time = elapsed * 0.3;
        vec3 rainbow = lch_to_rgb(vec3(0.75, 1, fract(vertex_position / rainbow_width - time)));
        color.rgb = color.rgb * rainbow;
    }

    return color;
}

#endif
