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

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 5;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos -= vec2(0.5);
    pos.x *= (love_ScreenSize.x / love_ScreenSize.y);

    float weight = gaussian(distance(pos.xy, vec2(0)), 0, 2);
    float scale = 10;
    float rng = worley_noise(vec3(pos.xy * weight * scale, time));

    // compute gradient (direction of space derivative)
    float pixel_size_x = 1 / love_ScreenSize.y;
    float pixel_size_y = 1 / love_ScreenSize.y;
    mat3 sobel_horizontal = mat3(
        -1.0, 0.0, 1.0,
        -2.0, 0.0, 2.0,
        -1.0, 0.0, 1.0
    );

    mat3 sobel_vertical = mat3(
        -1.0, -2.0, -1.0,
        0.0,  0.0,  0.0,
        1.0,  2.0,  1.0
    );

    float horizontal_sum = 0;
    float vertical_sum = 0;
    float value = worley_noise(vec3(pos.xy * weight * scale, time));
    for (int i = -1; i <= 1; ++i)
    {
        for (int j = -1; j <= 1; ++j)
        {
            float value = worley_noise(vec3((pos.xy + vec2(i * pixel_size_x, j * pixel_size_y)) * weight * scale, time)) ;
            vertical_sum += sobel_vertical[i + 1][j + 1] * value;
            horizontal_sum += sobel_horizontal[i + 1][j + 1] * value;
        }
    }

    float direction = angle(vec2(horizontal_sum, vertical_sum)) + PI;
    float magnitude = gaussian(rng, 0, 0.075);

    vec2 warped_position = translate_point_by_angle(texture_coords, direction, magnitude);
    return vec4(vec3(warped_position.y), 1);
    //return vec4(vec3(hsv_to_rgb(vec3((direction + PI) / (2 * PI), 1, magnitude))), 1);
}

#endif
