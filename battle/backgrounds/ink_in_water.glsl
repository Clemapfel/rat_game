#define PI 3.1415926535897932384626433832795

float simplex_noise(in vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    i = i - floor(i * (1. / 289.));

    vec4 p = ((i.z + vec4(0.0, i1.z, i2.z, 1.0)) * 34.0 + 1.0) * (i.z + vec4(0.0, i1.z, i2.z, 1.0)) - floor(((i.z + vec4(0.0, i1.z, i2.z, 1.0)) * 34.0 + 1.0) * (i.z + vec4(0.0, i1.z, i2.z, 1.0)) * (1. / 289.)) * 289.;
    p = ((p + i.y + vec4(0.0, i1.y, i2.y, 1.0)) * 34.0 + 1.0) * (p + i.y + vec4(0.0, i1.y, i2.y, 1.0)) - floor(((p + i.y + vec4(0.0, i1.y, i2.y, 1.0)) * 34.0 + 1.0) * (p + i.y + vec4(0.0, i1.y, i2.y, 1.0)) * (1. / 289.)) * 289.;
    p = ((p + i.x + vec4(0.0, i1.x, i2.x, 1.0)) * 34.0 + 1.0) * (p + i.x + vec4(0.0, i1.x, i2.x, 1.0)) - floor(((p + i.x + vec4(0.0, i1.x, i2.x, 1.0)) * 34.0 + 1.0) * (p + i.x + vec4(0.0, i1.x, i2.x, 1.0)) * (1. / 289.)) * 289.;

    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    vec4 f = vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3));
    vec4 norm = 1.79284291400159 - 0.85373472095314 * f;

    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;

    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float square_wave_sin(float x) {
    float smoothness = 100.0;
    return atan(smoothness * sin(2.0 * PI * x)) / PI + 0.5;
}

float square_wave_cos(float x) {
    float smoothness = 100.0;
    return atan(smoothness * cos(2.0 * PI * x)) / PI + 0.5;
}


float triangle_wave(float x)
{
    float pi = 2 * (335 / 113); // 2 * pi
    return 4 * abs((x / pi) + 0.25 - floor((x / pi) + 0.75)) - 1;
}


vec3 oklch_to_rgb(vec3 lch)
{
    float theta = clamp(lch.z, 0, 1) * (2 * PI);
    float l = lch.x;
    float chroma = lch.y;
    float a = chroma * cos(theta);
    float b = chroma * sin(theta);
    vec3 c = vec3(l, a, b);

    const mat3 fwdA = mat3(1.0, 1.0, 1.0,
                           0.3963377774, -0.1055613458, -0.0894841775,
                           0.2158037573, -0.0638541728, -1.2914855480);

    const mat3 fwdB = mat3(4.0767245293, -1.2681437731, -0.0041119885,
                           -3.3072168827, 2.6093323231, -0.7034763098,
                           0.2307590544, -0.3411344290,  1.7068625689);
    vec3 lms = fwdA * c;
    return fwdB * (lms * lms * lms);
}

/// @brief worley noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/worley.glsl
float worley_noise(vec3 p) {
    vec3 n = floor(p);
    vec3 f = fract(p);

    float dist = 1.0;
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 g = vec3(i, j, k);

                vec3 p = n + g;
                p = fract(p * vec3(0.1031, 0.1030, 0.0973));
                p += dot(p, p.yxz + 19.19);
                vec3 o = fract((p.xxy + p.yzz) * p.zyx);

                vec3 delta = g + o - f;
                float d = length(delta);
                dist = min(dist, d);
            }
        }
    }

    return 1 - dist;
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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    // inspired by: https://www.shadertoy.com/view/4td3RN
    vec2 uv = (vertex_position / love_ScreenSize.xy);
    float x_normalization = love_ScreenSize.x / love_ScreenSize.y;

    uv.x = uv.x * x_normalization;
    uv.x += 0.5 * x_normalization;
    float time = elapsed / 16;

    uv.x += time / 4;
    uv.y += time / 2;
    uv *= 1.5;

    const float n_steps = 50;
    float lacunarity = 0.25;
    const float step_multiplier = 1.2;

    for(int i = 1; i < n_steps; i++)
    {
        uv.x += lacunarity / i * sin(i * uv.y * step_multiplier + time) + 0.5 * i;
        uv.y += lacunarity / i * cos(i * uv.x * step_multiplier - time) - 0.5 * i;
    }

    float x_bias = (cos(uv.x * 3) + 1) / 2;
    float y_bias = (sin((uv.y + 0.5) * 3) + 1) / 2;

    vec3 color = lch_to_rgb(vec3(0.75 + 0.05 * (simplex_noise(uv.xyx) * 2 - 1), 0.9, length(vec2(x_bias, y_bias))));
    return vec4(color, 1);
}

#endif
