/*
float gaussian(float x, float ramp) {
    return exp(((-4 * 3.14159265359) / 3) * (ramp * x) * (ramp * x));
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

uniform float elapsed;

vec4 effect(vec4 vertex_color, sampler2D image, vec2 texture_coords, vec2 screen_coords)
{
    float dist = texture(image, texture_coords).a;
    float eps = 0.05; //length(vec2(dFdx(dist), dFdy(dist)));
    float regular = smoothstep(0.5 - eps, 0.5 + eps, dist);

    vec3 outline_color = lch_to_rgb(vec3(0.8, 1, texture_coords.y * 4 + elapsed));
    float outline = 2 * dist;
    return vec4(outline_color, outline) - regular + vertex_color * vec4(regular);
}
*/

uniform float screenPxRange = 2.0f;

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3 msd = Texel(tex, texture_coords).rgb;
    float sd = median(msd.r, msd.g, msd.b) - 0.5f;
    float screenPxDistance = screenPxRange * sd;
    float opacity = clamp(screenPxDistance + 0.5, 0.0, 1.0);

    color.a *= opacity;
    return color;
}
