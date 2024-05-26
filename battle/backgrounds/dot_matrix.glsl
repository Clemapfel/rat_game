
#define PI 3.1415926535897932384626433832795

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

float project(float value, float lower, float upper) {
    return value * abs(upper - lower) + min(lower, upper);
}

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

#ifdef PIXEL

uniform float radius;
uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 10;

    float aspect_factor = love_ScreenSize.x / love_ScreenSize.y;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos.x *= aspect_factor;

    float n_rows = 100;
    float radius = 1 / n_rows;
    float grid_size = radius * 2;

    int x_i = int(floor(pos.x / grid_size));
    int y_i = int(floor(pos.y / grid_size));

    vec2 center = vec2(float(x_i) * grid_size + radius, float(y_i) * grid_size + radius);

    radius = project(worley_noise(vec3(pos.xy * 5, time)), 0.7 * radius, 1 * radius);

    float border = 0.005;
    float dist = radius - distance(pos, center);

    float value = 0.0;
    if (dist > border)
        value = 1.0;
    else if (dist > 0.0)
        value = dist / border;  // draw with feathered edge

    value = value * 0.6;
    return vec4(vec3(value), 1);
}

#endif
