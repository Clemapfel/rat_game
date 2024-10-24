vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

const float PI = 3.14159265359;
float angle(vec2 v)
{
    return (atan(v.y, v.x) + PI);
}

vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

layout(rgba32f) uniform image2D position_texture;
layout(rgba8) uniform image2D color_texture;
layout(r8) uniform image2D mass_texture;

uniform vec4 aabb;
uniform sampler2D snapshot;
uniform vec2 snapshot_size;
uniform float pixel_size;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    vec2 position = gl_GlobalInvocationID.xy;
    vec2 texture_coords = position / snapshot_size * pixel_size;

    vec3 random = random_3d(vec3(position.xy, 0));

    // init color
    vec4 color = texture(snapshot, texture_coords);
    imageStore(color_texture, ivec2(position.x, position.y), color);

    // init mass
    imageStore(mass_texture, ivec2(position.x, position.y), vec4(random.x));

    // init position
    vec2 center = aabb.xy + 0.5 * aabb.zw;
    vec2 current = vec2(aabb.x, aabb.y) + texture_coords * aabb.zw;
    vec2 previous = current;

    previous = translate_point_by_angle(previous, 1, angle(current - center));

    imageStore(position_texture, ivec2(position.x, position.y), vec4(current, previous));
}