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

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with 1, 1
void computemain()
{
    if (gl_GlobalInvocationID.x != 0) return;

    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_in[i];
        uint count = atomicAdd(global_counts[particle.cell_id], -1u);
        particles_out[count] = particles_in[i];
    }

    // TODO
    if (gl_GlobalInvocationID.x == 0) {
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