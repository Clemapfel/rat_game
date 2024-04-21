#pragma language glsl4

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

float sine_wave(float x, float frequency) {
    return (sin(2.0 * 3.14159 * x * frequency - 3.14159 / 2.0) + 1.0) * 0.5;
}

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

float exponential_acceleration(float x) {
    float a = 0.045;
    return a * exp(log(1.0 / a + 1.0) * x) - a;
}

float sigmoid(float x) {
    return 1.0 / (1.0 + exp(-1.0 * 9 * (x - 0.5)));
}

#ifdef PIXEL

uniform float time;
uniform float intensity;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float x = vertex_position.x;
    float y = vertex_position.y;
    vec2 size = love_ScreenSize.xy;
    float factor = 100;
    vec3 as_hsv = vec3(
        sine_wave(-1 * time + distance(vec2(x, y) / factor, size * 0.5 / factor), 0.2) * (1 + intensity),
        project(sigmoid(1.5 * (1 - ((y + intensity) / size.y))), 0.2, 1),
        1
    );
    as_hsv.x = project(as_hsv.x, 0.5, 0.9);
    return vec4(hsv_to_rgb(as_hsv), 1);
}

#endif
