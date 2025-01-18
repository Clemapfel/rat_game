#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform sampler2D density_texture;

#ifdef VERTEX

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    Particle particle = particles[instance_id];
    vertex_position.xy += particle.position;
    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL
vec4 effect(vec4 vertex_color, Image _, vec2 texture_coords, vec2 vertex_position)
{
    vec4 texel = texture(density_texture, texture_coords);
    return vec4(texel.r, 0, 0, 1);
}

#endif
