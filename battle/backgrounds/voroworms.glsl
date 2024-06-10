#define PI 3.1415926535897932384626433832795

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

float angle(vec2 v)
{
    return atan(v.y, v.x);
}

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}


/// @brief simplex noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/snoise.glsl
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

/// @brief fbm noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/fbm.glsl
float fractal_brownian_motion_noise(vec3 p) {
    const float persistence = 0.5;
    const int n_octaves = 4;

    float amplitude = 0.5;
    float total = 0.0;
    float normalization = 0.0;

    for (int i = 0; i < n_octaves; ++i) {
        float noiseValue = gradient_noise(p) * 0.5 + 0.5;
        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
    }

    return total / normalization;
}


/// @brief voronoi noise
/// @param blur in [0, 1]
/// @param squareness in [0, 1], 0: square, 1: random
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/voronoise.glsl
float voronoise(vec3 p, float blur, float squareness) {
    blur = clamp(blur, 0, 1);
    float u = squareness;
    float k = 1.0 + 63.0 * pow(1.0 - blur, 6.0);
    vec3 i = floor(p);
    vec3 f = fract(p);

    float s = 1.0 + 31.0 * blur;
    vec2 a = vec2(0.0, 0.0);

    vec3 g = vec3(-2.0);
    for (g.z = -2.0; g.z <= 2.0; g.z++)
    for (g.y = -2.0; g.y <= 2.0; g.y++)
    for (g.x = -2.0; g.x <= 2.0; g.x++) {
        vec3 v = i + g;
        v = fract(v * vec3(.1031, .1030, .0973));
        v += dot(v, v.yxz + 19.19);
        vec3 o = fract((v.xxy + v.yzz) * v.zyx) * vec3(u, u, 1.);
        vec3 d = g - f + o + 0.5;
        float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
        a += vec2(o.z * w, w);
    }
    return a.x / a.y;
}

float map(float value, float inputMin, float inputMax, float outputMin, float outputMax) {
    return outputMin + ((outputMax - outputMin) / (inputMax - inputMin)) * (value - inputMin);
}

float sine_wave(float x, float lower, float upper) {
    return map((sin(2 * PI * x * 2 - PI / 2) + 1) * 0.5, -1, 1, lower, upper);
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 5;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos -= vec2(0.5);
    pos.x *= (love_ScreenSize.x / love_ScreenSize.y);
    pos *= 1.5;

    float weight = gaussian(distance(pos.xy, vec2(0)) * 2.2, 0.5, 0.5);
    float offset = 0.01;
    vec2 rng_pos = pos.xy * weight * 10;
    rng_pos = rotate(rng_pos, 2 * distance(pos.xy, vec2(0) / PI) + elapsed / 20);
    float rng = voronoise(
        vec3(rng_pos, time),
        sine_wave(time / 4, 0.4 - offset, 0.4 + offset),
        0.7
    );

    float derivative = fwidth(rng);
    float value = 10 * derivative;
    return vec4(vec3(value), 1);
}

#endif
