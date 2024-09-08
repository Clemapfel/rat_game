#define PI 3.1415926535897932384626433832795


vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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


// @param l lightness, [0, 1]
// @param c chroma [0, 1]
// @param h hue [0, 1]
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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 5;
    vec2 pos = vertex_position.xy / love_ScreenSize.xy;
    pos -= vec2(0.5);
    pos.x *= (love_ScreenSize.x / love_ScreenSize.y);

    float weight = gaussian(distance(pos.xy, vec2(0)), 0, 4);
    float scale = 6;
    float magnitude = fwidth(gradient_noise(vec3(pos.xy * weight * scale, time))) * 60;
    magnitude = clamp(magnitude * 1, 0, 1);

    vec3 hsv = vec3(magnitude, 0, magnitude);
    return vec4(hsv_to_rgb(hsv), 1);
}

#endif
