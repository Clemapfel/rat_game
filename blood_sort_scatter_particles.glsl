//
// reorder particles based on prefix sum
//

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) readonly buffer particle_buffer_in {
    Particle particles_in[];
}; // size: n_particles

layout(std430) buffer particle_buffer_out { // TODO: writeonly
    Particle particles_out[];
}; // size: n_particles

uniform uint n_particles;

layout(std430) buffer global_counts_buffer {
    uint global_counts[];
}; // size: n_columns * n_rows

layout(std430) buffer is_sorted_buffer {
    uint is_sorted[];
}; // size: 1

#ifndef LOCAL_SIZE
#define LOCAL_SIZE 1
#endif

layout (local_size_x = LOCAL_SIZE, local_size_y = LOCAL_SIZE, local_size_z = 1) in; // dispatch with 1, 1
void computemain()
{
    uint thread_i = gl_LocalInvocationID.y * gl_WorkGroupSize.x + gl_LocalInvocationID.x;
    uint n_particles_per_thread = uint(ceil(n_particles / float(gl_WorkGroupSize.x * gl_WorkGroupSize.y)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; particle_i++) {
        uint index = particles_in[particle_i].cell_id;
        uint count = atomicAdd(global_counts[index], 1u);

        //particles_out[count] = particles_in[particle_i];
        particles_out[particle_i] = particles_in[particle_i];
    }

    // TODO
    if (thread_i == 0) {
        bool sorted = true;
        for (uint i = 0; i < n_particles - 1; ++i) {
            Particle current = particles_out[i];
            Particle next = particles_out[i+1];
            if (current.cell_id > next.cell_id) {
                sorted = false;
                break;
            }
        }

        is_sorted[0] = sorted ? 1u : 0u;
    }
    // TODO
}