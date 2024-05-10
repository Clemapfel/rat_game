#pragma language glsl4

#ifdef PIXEL

#define PI 3.1415926535897932384626433832795

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

// get angle of vector in 0, 1
float angle(vec2 v)
{
    return (atan(v.x, v.y) + PI) / (2 * PI);
}

// translate by angle
vec2 translate_point_by_angle(vec2 xy, float distance, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * distance;
}

float sine_wave(float x, float frequency) {
    return (sin(2.0 * PI * x * frequency - PI / 2.0) + 1.0) * 0.5;
}

float angle_to_radians(float v) {
    return (v * 2 * PI) - PI;
}

// ###

uniform float elapsed;
uniform vec2 texture_size;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 xy = texture_coords - vec2(0.5, 0.5);
    float angle = angle(xy);
    float magnitude = 1;

    float time = -1 * elapsed / 4;
    angle = fract(angle + length(xy) + time);

    vec2 warped_pos = translate_point_by_angle(texture_coords, length(xy) / 2, angle);
    return mix(Texel(image, warped_pos), vec4(hsv_to_rgb(vec3(angle, 0, angle)), 1), 0.9);
}

#endif
