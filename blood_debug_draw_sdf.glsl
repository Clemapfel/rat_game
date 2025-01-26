#ifdef PIXEL

#define PI 3.1415926535897932384626433832795

float gaussian(float x, float ramp)
{
    // e^{-\frac{4\pi}{3}\left(r\cdot\left(x-c\right)\right)^{2}}
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
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

uniform float elapsed;

uniform sampler2D hitbox_texture_a; // x: is wall
uniform sampler2D hitbox_texture_b;

vec4 effect(vec4 color, Image sdf_texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture(sdf_texture, texture_coords);
    vec2 size = textureSize(sdf_texture, 0);
    float dist = pixel.z / (max(size.x, size.y) / 2);
    float magnitude = length(pixel.xy) / (max(size.x, size.y) / 2);
    float angle = (atan(pixel.y, pixel.x) + PI) / (2 * PI);

    const float intensity = 0.1;
    float hitbox_a = texture(hitbox_texture_a, texture_coords).r;
    float hitbox_b = texture(hitbox_texture_b, texture_coords).r;
    float hitbox = max(hitbox_a, hitbox_b) * intensity;

    float is_wall = float(pixel.a <= 0);
    return vec4(lch_to_rgb(vec3(0.8, length(pixel.xy), angle)), 1);
}

#endif