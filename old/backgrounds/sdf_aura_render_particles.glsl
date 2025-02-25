#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    float radius;
    float radius_velocity;
    vec3 color;
};

layout(std430) buffer readonly particle_buffer {
    Particle particles[];
}; // size: n_particles

#ifdef VERTEX

varying vec3 color;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    Particle particle = particles[instance_id];

    bool is_center = gl_VertexID == 0;
    if (is_center)
        vertex_position.xy += particle.position;
    else {
        float angle = atan(vertex_position.y, vertex_position.x); // mesh centroid is 0, 0
        vertex_position.xy += particle.position + vec2(cos(angle), sin(angle)) * particle.radius;
    }

    color = particle.color;
    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec3 color;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position)
{
    return vec4(vec3(color), 1) * texture(image, texture_coords);
}

#endif
