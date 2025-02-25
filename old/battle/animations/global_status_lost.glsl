#define PI 3.1415926535897932384626433832795

/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

/// @brief gradient noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/gnoise.glsl
float gradient_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    float result = mix( mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );

    return result;
}

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float uniform_noise(vec2 st) {
    return hash(dot(st, vec2(12.9898, 78.233)));
}

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

uniform float elapsed;
uniform float duration = 1;
uniform int n_instances;

#ifdef VERTEX

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    float x = uniform_noise(vec2(-instance_id, +instance_id)) * love_ScreenSize.x;
    float y = uniform_noise(vec2(+instance_id, -instance_id) + 1234) * love_ScreenSize.y;

    float threshold = smoothstep(0, 1, float(instance_id) / float(n_instances) + elapsed);

    vec2 destination = vec2(love_ScreenSize.x, 0);
    vec2 diff = vec2(x, y) - destination;
    vec2 offset = translate_point_by_angle(vec2(x, y), elapsed * threshold * love_ScreenSize.x, atan(diff.x, diff.y)); // sic, flip

    vertex_position.xy += offset;
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    return Texel(image, texture_coords) * vertex_color;
}
#endif