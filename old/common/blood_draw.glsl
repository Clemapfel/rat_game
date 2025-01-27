#pragma language glsl4

#ifdef VERTEX

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

vec2 rotate(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * v;
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
};

varying vec3 color;

vec4 position(mat4 transform, vec4 vertex_position)
{
    Particle particle = particles[love_InstanceID];

    vec2 center = vec2(0);
    float angle = atan(vertex_position.y - center.y, vertex_position.x - center.x);
    vertex_position.xy = translate_point_by_angle(vec2(0), particle.radius, angle);
    vertex_position.xy = rotate(vertex_position.xy, particle.angle);
    vertex_position.xy += particle.current_position;

    color = hsv_to_rgb(vec3(particle.color, 1, 1));
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec3 color;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 _)
{
    return vertex_color * vec4(color, 1);
}
#endif