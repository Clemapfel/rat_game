//
// sequentially radix sort an array of pairs by hash
//

struct ParticleOccupation {
    uint id;
    uint hash;
};

layout(std430) buffer particle_occupation_buffer {
    ParticleOccupation particle_occupations[];
}; // size: n_particles

layout(std430) buffer particle_occupation_swap_buffer {
    ParticleOccupation swap[];
}; // size: n_particles

layout(std430) buffer global_counts_buffer {
    uint global_counts[];
}; // size: n_bins

layout(std430) buffer global_offsets_buffer {
    uint global_offsets[];
}; // size: n_bins

uniform uint n_particles;

#define GET(pass, i) (pass % 2 == 0 ? particle_occupations[i].hash : swap[i].hash)

layout (local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() // 1, 1 invocations
{
    uint thread_x = gl_GlobalInvocationID.x;
    uint group_x = gl_LocalInvocationID.x;

    bool is_sequential_worker = thread_x == 0 && group_x == 0;

    const uint n_bins = 256;
    const uint bitmask = 0xFFu;

    for (uint pass = 0u; pass < 4u; pass++)
    {
        uint shift = 8 * pass;
        if (is_sequential_worker) {
            for (uint i = 0; i < n_bins; ++i)
            global_counts[i] = 0u;

            for (uint i = 0; i < n_particles; ++i) {
                uint masked = (GET(pass, i) >> shift) & bitmask;
                atomicAdd(global_counts[masked], 1u);
            }

            uint sum = 0u;
            for (uint i = 0; i < n_bins; ++i) {
                uint count = global_counts[i];
                atomicExchange(global_offsets[i], sum);
                sum += count;
            }

            for (uint i = 0; i < n_particles; ++i) {
                uint masked = (GET(pass, i) >> shift) & bitmask;

                if (pass % 2 == 0)
                swap[global_offsets[masked]] = particle_occupations[i];
                else
                particle_occupations[global_offsets[masked]] = swap[i];

                global_offsets[masked]++;
            }
        }

        barrier();
    }

    for (int i = 1; i < n_particles; ++i)
        particle_occupations[i] = swap[i];
}