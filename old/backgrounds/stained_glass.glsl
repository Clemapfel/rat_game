#define PI 3.1415926535897932384626433832795

/// @brief 2d discontinuous noise, in [0, 1]
vec2 random_2d(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 voronoi(vec2 uv) {
    // src: https://www.shadertoy.com/view/MclyRr

    vec2 uv_id = floor(uv);
    vec2 uv_st = fract(uv);

    vec2 m_diff;
    vec2 m_point;
    vec2 m_neighbor;

    float m_dist = 1;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 neighbor = vec2(float(i), float(j));
            vec2 point = random_2d(vec3(uv_id + neighbor, 0));
            vec2 diff = neighbor + point - uv_st;

            float dist = length(diff);
            if (dist < m_dist) {
                m_dist = dist;
                m_point = point;
                m_diff = diff;
                m_neighbor = neighbor;
            }
        }
    }

    m_dist = 1;
    for(int j = -2; j <= 2; j++){
        for(int i = -2; i <= 2; i++){
            if (i == 0 && j == 0) continue;
            vec2 neighbor = m_neighbor+ vec2(float(i), float(j));
            vec2 point = random_2d(vec3(uv_id+neighbor, 0));
            vec2 diff = neighbor + point- uv_st;
            float dist = dot(0.5 * (m_diff+diff), normalize(diff - m_diff));
            m_point = point;
            m_dist = min(m_dist, dist);
        }
    }

    return vec3(m_point, m_dist);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float simplex_noise(in vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 pos = vertex_position.xy / love_ScreenSize.xy;
    pos.y *= love_ScreenSize.y / love_ScreenSize.x;

    float time = 0.5 * elapsed;
    vec3 tiled = voronoi(pos.xy * 10);
    float hue = tiled.y;

    const float line_width = 0.01;
    const float center = 0.03;
    float outline = smoothstep(center - line_width, center + line_width, tiled.z);
    vec3 color = hsv_to_rgb(vec3(hue, 1, 1));
    return vec4(vec3(color * outline), 1);
}

#endif
