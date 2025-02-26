#pragma language glsl4

struct Particle {
    vec2 current;
    float angle;
    float velocity;
    float damping;
    float hue;
    float radius;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
};

#ifdef VERTEX

uniform vec3 red;
uniform float opacity;
uniform float radius_factor;

varying vec4 color;

vec4 position(mat4 transform, vec4 vertex_position)
{
    Particle particle = particles[love_InstanceID];

    float angle = atan(vertex_position.y, vertex_position.x); // mesh centroid is 0, 0
    vertex_position.xy = vec2(0) + vec2(cos(angle), sin(angle)) * particle.radius * radius_factor;
    vertex_position.xy += particle.current;

    color = vec4(red, opacity);
    color.rgb *= particle.hue;
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 color;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    return color * vertex_color;
}

#endif