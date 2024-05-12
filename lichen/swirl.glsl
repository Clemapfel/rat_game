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

// get angle of vector in [0, 1]
float angle(vec2 v)
{
    return (atan(v.y, v.x) + PI) / (2 * PI);
}

// translate by angle
vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float sine_wave(float x, float frequency) {
    return (sin(2.0 * PI * x * frequency - PI / 2.0) + 1.0) * 0.5;
}

float angle_to_radians(float v) {
    return (v * 2 * PI) - PI ;
}

// ###

uniform float elapsed;
uniform vec2 texture_size;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    texture_coords -= vec2(0.5);
    texture_coords *= 1.3;
    texture_coords += vec2(0.5);

    // scale time for animation speed
    float time = elapsed / 2;

    // distance from center
    float dist = length(texture_coords - vec2(0.5));

    // angle, in [0, 1]
    float dg = angle(texture_coords - vec2(0.5));

    // offset angle, scaled by distance from center
    dg = dg + time * (1 - dist);

    // apply vector to original fragment position
    vec2 warped_pos = translate_point_by_angle(vec2(0.5), dist, angle_to_radians(dg));
    //warped_pos.x = 1 - warped_pos.x;
    //return vec4(hsv_to_rgb(vec3(dg, 1, 1)), 1);
    return Texel(image, warped_pos);
}

#endif

/*

uniform float elapsed;
uniform vec2 texture_size;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 8;
    float dist = length(texture_coords - vec2(0.5));
    float dg = angle(texture_coords - vec2(0.5));

    float rng = random(texture_coords) ;
    vec2 warped_pos = translate_point_by_angle(texture_coords, time, angle_to_radians(-1 * dg));
    vec3 as_hsv = vec3(angle(warped_pos - vec2(0.5)), 1, 1);

    return Texel(image, warped_pos);
}
*/


