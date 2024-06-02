#pragma language glsl4

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

#define PI 3.1415926535897932384626433832795

float angle_between(vec2 v1, vec2 v2) {
    return (acos(clamp(dot(normalize(v1), normalize(v2)), -1.0, 1.0)) + PI) / (2 * PI);
}

// ###

#define SHADER_MODE_INITIALIZE -1
#define SHADER_MODE_DRAW 0
#define SHADER_MODE_STEP 1

uniform int mode;
uniform float seed;
uniform Image texture_from;
uniform vec2 texture_size;
uniform float delta;
uniform float elapsed;

vec4 effect(vec4 vertex_color, Image _, vec2 texture_coords, vec2 vertex_position)
{
    if (mode == SHADER_MODE_INITIALIZE)  // initialize
    {
        return vec4(simplex_noise(vec3(texture_coords.xy * 10000, seed)));
    }
    else if (mode == SHADER_MODE_DRAW) // draw
    {
        vec4 value = Texel(texture_from, texture_coords.xy);
        return vec4(vec3(length(value.xy)), 1);
    }

    vec2 pixel_size = 1.f / texture_size;
    vec4 current = Texel(texture_from, texture_coords.xy);

    float n_neighbors = 0;
    float max_angle = -1. / 0.;
    float neighborhood_sum = 0;

    int x = int(texture_coords.x / pixel_size);
    int y = int(texture_coords.y / pixel_size);

    vec2 vector = vec2(0);
    for (int xx = x - 1; xx <= x + 1; xx++) {
        for (int yy = y - 1; yy <= y + 1; yy++) {
            //if (xx == x || yy == y) continue;

            vec4 current = Texel(texture_from, vec2(xx, yy) * pixel_size);
            if (current.z > 0.97)
                n_neighbors++;

            for (int xxx = x-1; xxx <= x+1; xxx++) {
                for (int yyy = y - 1; yyy < y + 1; yyy++) {
                    vec4 other = Texel(texture_from, vec2(xxx, yyy) * pixel_size);
                    max_angle = max(max_angle, angle_between(current.xy, other.xy) + PI);
                }
            }

            vec2 came_from = normalize(vec2(xx - x, yy - y));
            vector = current.z * (current.xy + came_from) / 2;
            vector = normalize(vector);
        }
    }

    float rng = elapsed;
    float rng_offset = simplex_noise(vec3(vec2(x, y) + vec2(rng, -rng), 0)) * 2;

    if (current.z <= 0 && n_neighbors > 1 * rng_offset && n_neighbors < 2 * rng_offset) {
        return vec4(vector, 1, 0);
    }
    else
    {
        return vec4(vector, clamp(current.z - 0.01, 0, 1), 0);
    }
}