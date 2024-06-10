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

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float laplacian_of_guassian(float x, float mean, float variance) {
    x = x - mean;
    return (1.0 - (x * x) / (variance * variance)) * exp(-0.5 * (x * x) / (variance * variance));
}

// get angle of vector
float angle(vec2 v)
{
    return (atan(v.y, v.x) + PI) / (2 * PI);
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
    vec2 pos = texture_coords.xy;
    vec2 center = vec2(0.5);

    pos.x *= love_ScreenSize.x / love_ScreenSize.y;
    center.x *= love_ScreenSize.x / love_ScreenSize.y;

    float factor = 1.5;
    pos *= factor;
    center *= factor;

    float angle = atan(pos.y - center.y, pos.x - center.x);

    pos.xy = rotate(pos.xy - center, elapsed / 20) + center;
    float rng = worley_noise(vec3(pos.xy * 8, elapsed / 5)) * (((sin(elapsed) + 1) / 2 * 0.5) + 0.75);
    float value = 1 - smoothstep(0, distance(pos.xy, center) * 5 * rng, 1);

    return vec4(vec3(value), 1);
}

#endif
