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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 pos = texture_coords.xy;
    pos.y *= love_ScreenSize.y / love_ScreenSize.x;

    vec3 tiled = voronoi(pos.xy * 10);
    float hue = tiled.y;

    const float line_width = 0.01;
    const float center = 0.03;
    float outline = smoothstep(center - line_width, center + line_width, tiled.z);
    vec3 color = hsv_to_rgb(vec3(hue, 1, 1));
    return vec4(vec3(color * outline), 1);
}

#endif
