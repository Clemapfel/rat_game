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

float voronoise(vec3 p, float blur) {
    blur = clamp(blur, 0, 1);
    float u = 0.55;
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

float project(float value, float lower, float upper)
{
    return value * abs(upper - lower) + min(lower, upper);
}

float angle(vec2 v)
{
    return atan(v.y, v.x);
}

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

float angle(vec3 v1) {
    const vec3 v2 = vec3(0, 0, 0);
    return acos(dot(normalize(v1), normalize(v2)));
}

vec3 disk_to_ball(vec2 diskPos, float radius) {
    float theta = 2.0 * PI * diskPos.x;
    float phi = PI * diskPos.y;

    float x = radius * sin(phi) * cos(theta);
    float y = radius * sin(phi) * sin(theta);
    float z = radius * cos(phi);

    return vec3(x, y, z);
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 2;
    vec2 pos = texture_coords.xy;
    pos.x *= love_ScreenSize.x / love_ScreenSize.y;

    float max_radius = 1;
    vec2 center = vec2(0.5, 0.5);
    center.x *= love_ScreenSize.x / love_ScreenSize.y;

    float sum = 0;
    const int n_steps = 4;
    for (int i = 0; i < n_steps; ++i)
    {
        float radius = max_radius * (i + 1) / float(n_steps);
        const float scale = 3; // spikyness of rng
        const float amplitude = 0.1;
        vec2 rng_pos = translate_point_by_angle(vec2(0.5), 0.5, angle(pos - center));
        radius = radius + project(voronoise(vec3(rng_pos * scale * (i + 1) * 2, time), 1), -amplitude, + amplitude);
        float dist = (radius - distance(pos, center)) * 3;

        float border = 0.005;
        float value = 1 - smoothstep(dist - border, dist + border, distance(pos, center));
        sum = sum + value * (i + 1) / float(n_steps);
    }
    sum = sum / 3;
    return vec4(vec3(sum), 1);
}

#endif
