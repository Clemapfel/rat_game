uniform sampler2D cell_texture;
uniform sampler2D flux_texture_top;
uniform sampler2D flux_texture_center;
uniform sampler2D flux_texture_bottom;

#define PI 3.1415926535897932384626433832795

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

uniform float gravity = 1;

vec2 directions[9] = vec2[9](
    vec2(-1, -1),
    vec2(0, -1),
    vec2(1, -1),

    vec2(-1, 0),
    vec2(0, 0),
    vec2(1, 0),

    vec2(-1, 1),
    vec2(0, 1),
    vec2(1, 1)
);

vec4 effect(vec4 _, Image __, vec2 texture_coords, vec2 screen_coords) {
    vec4 cell = texture(cell_texture, texture_coords);
    vec4 flux_top = texture(flux_texture_top, texture_coords);
    vec4 flux_center = texture(flux_texture_center, texture_coords);
    vec4 flux_bottom = texture(flux_texture_bottom, texture_coords);

    float flux[9];
    flux[0] = flux_top.x;
    flux[1] = flux_top.y;
    flux[2] = flux_top.z;
    flux[3] = flux_center.x;
    flux[4] = flux_center.y;
    flux[5] = flux_center.z;
    flux[6] = flux_bottom.x;
    flux[7] = flux_bottom.y;
    flux[8] = flux_bottom.z;

    vec2 flux_sum = vec2(0);
    for (int i = 0; i < 9; ++i) {
        flux_sum += directions[i] * flux[i];
    }

    float angle = (atan(cell.y, cell.x) + PI) / (2 * PI);
    float magnitude = length(cell.xy);


    vec3 color = lch_to_rgb(vec3(cell.x, min(magnitude, 1), angle));
    return vec4(vec3(color), 1.0);
}