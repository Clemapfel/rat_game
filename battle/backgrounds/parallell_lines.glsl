#define PI 3.1415926535897932384626433832795

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

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rotate(vec2 point, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    vec2 pivot = vec2(0.5, 0.5);
    point -= pivot;
    point = vec2(point.x * c - point.y * s, point.x * s + point.y * c);
    return point + pivot;
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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    const float scale = 4;
    const float rotation = PI / 6;

    vec2 pos = texture_coords;
    pos = rotate(pos, rotation);
    //float line_i = worley_noise(vec3(pos.xy * 0.75, elapsed / 25));
    const float rng_scale = 0.2;
    float line_i = pos.y * (1 / scale) + worley_noise(vec3(pos.xy * 0.2, elapsed / 30));
    pos = pos * scale;

    float y = pos.y;
    const float magnitude = 0.15;
    float direction = (sin(gradient_noise(vec3((pos.xy) * 1.2, elapsed / 10))) * 2) - 1;
    y += magnitude * direction;
    y = fract(y * scale);

    float width = mix(0.05, 0.5, (sin(elapsed) + 1) / 2);
    vec4 line = vec4(1 - smoothstep(0.0, width, abs(y - 0.5)));

    float hue = fract(fract(elapsed / 10) + line_i * 5 + elapsed / 12);
    return vec4(0, 0, 0, 1) + vec4(oklch_to_rgb(vec3(1, 0.3, hue)), 1) * line;
}

#endif
