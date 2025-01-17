struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

layout(r32ui) uniform uimage2D local_counts_texture;
uniform uint n_particles;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with n_thread_groups, 1
void computemain()
{
    uint texture_y = gl_WorkGroupID.x;
    uint n_particles_per_group = uint(ceil(n_particles / float(gl_NumWorkGroups.x)));
    uint start_i = gl_WorkGroupID.x * n_particles_per_group;
    uint end_i = min(start_i + n_particles_per_group, n_particles);

    for (uint i = start_i; i < end_i; ++i)
        imageAtomicAdd(local_counts_texture, ivec2(particles[i].cell_id, texture_y), 1u);
}