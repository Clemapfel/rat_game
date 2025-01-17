struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_index;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

layout(r32ui) uniform uimage2D local_counts_texture;
uniform uint n_particles;

#ifndef LOCAL_SIZE
    #define LOCAL_SIZE 64
#endif

layout (local_size_x = LOCAL_SIZE, local_size_y = 1, local_size_z = 1) in; // dispatch with n_thread_groups, 1
void computemain()
{
    uint n_groups = gl_NumWorkGroups.x;
    uint particles_per_group = uint(ceil(n_particles / float(n_groups)));

    uint start_i = gl_WorkGroupID.x * particles_per_group;
    uint end_i = min(start_i + particles_per_group, n_particles);

    for (uint i = start_i + gl_LocalInvocationID.x; i < end_i; i += gl_WorkGroupSize.x) {
        uint cell_i = particles[i].cell_index;
        imageAtomicAdd(local_counts_texture, ivec2(cell_i, gl_WorkGroupID.x), 1u);
    }
}