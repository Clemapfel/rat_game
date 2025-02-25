#pragma language glsl4

//
// draw particles using geometry instancing
//

struct Particle {
    vec2 position;
    vec2 velocity;
    float density;
    float near_density;
    uint cell_hash;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

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
vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 texel = texture(image, texture_coords);
    return vec4(texel.r, 0, 0, 1);
}

#endif
