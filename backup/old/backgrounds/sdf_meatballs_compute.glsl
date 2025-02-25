//#pragma language glsl4

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

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float sdf_circle(vec2 point, vec2 center,  float radius) {
    return length(point - center) - radius;
}

float sdf_ellipse(vec2 position, vec2 center, vec2 radius)
{
    // src: https://www.shadertoy.com/view/7lBXzV
    position -= center;
    position = abs(position);
    float d = max(abs(position.x - radius.x), position.y);
    d = min(d, max(position.x, abs(position.y - radius.y)));
    float a = dot(vec2(1.0), 1.0 / (radius * radius));
    float b = dot(vec2(1.0), position / (radius * radius));
    float c = dot(vec2(1.0), (position * position) / (radius * radius)) - 1.0;

    float discriminant = b * b - a * c;
    if (discriminant >= 0.0) {
        float t = (b - sqrt(discriminant)) / a;
        d = min(t, d);
    }

    return d;
}

float sdf_rectangle(vec2 point, vec2 center, vec2 size) {
    vec2 p = abs(point - center) - size / 2.0;
    vec2 distance_outside = max(p, vec2(0.0));
    float distance_inside = min(max(p.x, p.y), 0.0);
    return length(distance_outside) + distance_inside;
}

float smooth_min(float a, float b, float smoothness) {
    float h = max(smoothness - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / smoothness;
}

float smooth_max(float a, float b, float smoothness) {
    float h = exp(smoothness * a) + exp(smoothness * b);
    return log(h) / smoothness;
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

// ###

layout(rgba32f) uniform image2D sdf_out;

layout(rgba32f) uniform image2D circles;
uniform int n_circles;

uniform vec2 resolution;
uniform float elapsed;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 size = ivec2(resolution.x, resolution.y);
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    int width = size.x;
    int height = size.y;

    vec2 pos = (vec2(x, y) / resolution);
    float x_normalization = resolution.x / resolution.y;

    pos.x = pos.x * x_normalization - (resolution.x - resolution.y) / resolution.y / 2;

    float smoothness = 0.05;

    const int n_balls = 6;
    const int n_circles = 3;
    float time = elapsed / 8;
    float dist = 1;
    for (int ball_i = 1; ball_i <= n_balls; ++ball_i)
    {
        for (int offset_i = 1; offset_i <= n_circles; ++offset_i) {
            float angle = (ball_i) / float(n_balls) * (2 * PI) + (offset_i) / float(n_circles) * PI / (n_balls - 2);
            angle -= time;
            float offset = project((sin(time) + 1 / 2), 0.05, 0.4) * offset_i / n_circles;
            float radius = 0.05;
            vec2 center = translate_point_by_angle(vec2(0.5), offset, angle);
            dist = smooth_min(dist, sdf_circle(pos, center, radius), smoothness);
        }
    }

    imageStore(sdf_out, ivec2(x, y), vec4(vec3(1), dist));
}