#ifdef PIXEL

#define PI 3.1415926535897932384626433832795
float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

float smooth_min(float a, float b, float smoothness) {
    float h = max(smoothness - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / smoothness;
}

vec2 translate_point_by_angle(vec2 xy, float distance, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * distance;
}

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 4;
    const float y_scale = 2;

    float x_scale = 3;
    vec2 pos = texture_coords;
    pos.x = (pos.x - 0.5) * x_scale + 0.5;

    float compression_factor = 0.6 * gaussian(max(abs((pos.x - 0.5) / 2), 0), 1.2);

    float x_sign = sign(pos.x * 2 - 1);
    float weight = x_sign > 0 ? 0.5 : 0; //mix(0.5, 0.0, smoothstep(0.0, 1.0, x_sign));
    float y = (compression_factor * sin(10 * (x_sign * (1 - pos.x) + time + weight * 0.5)) + 1 + y_scale / 2) / (2 * y_scale);
    float density = gaussian(pos.x - 0.5, 1) * 1.06;
    density *= (1 - (distance(pos.xy * vec2(1, 1), vec2(0.5))) / 5);
    float eps = 0.0075 * exp2((1 - abs(texture_coords.x - 0.5)));
    float value = smoothstep(0, eps, (1 - density) * distance(y, pos.y));

    float y_normalization = love_ScreenSize.y / love_ScreenSize.x;
    float radius = 0.10; // Set the desired radius for the circle
    float ball = smoothstep(
        radius,
        radius + 3 * eps,
        (0.9 * value) * (0.05 + abs(texture_coords.x - 0.5)) * abs((texture_coords.y - 0.5) * 1.2) * 100 * distance(texture_coords.xy * vec2(1, y_normalization), vec2(0.5, 0.5 * y_normalization))
    );
    value = smooth_min(value, ball, 0.25);

    float iris_radius = 0.01;
    float iris = (1 - smoothstep(iris_radius, iris_radius + 0.07, distance(texture_coords * vec2(1, y_normalization), vec2(0.5) * vec2(1, y_normalization))));
    return vec4(vec3(smoothstep(0, 0.6, max(value, iris))), 1);
}

#endif