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

#define n_bins 256
#define GET(pass, i) (pass % 2 == 0 ? particle_occupations[i].hash : swap[i].hash)

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() // 1, 1 invocations
{
    uint global_x = gl_GlobalInvocationID.x;
    uint local_x = gl_LocalInvocationID.x;
    uint group_x = gl_WorkGroupID.x;

    bool is_sequential_worker = global_x == 0 && local_x == 0;

    const uint bitmask = 0xFFu;
    uint local_counts[n_bins];

    for (uint pass = 0u; pass < 4u; pass++)
    {
        uint shift = 8 * pass;

        if (global_x < n_bins) {
            global_counts[global_x] = 0u;
            global_offsets[global_x] = 0u;
        }

        barrier();

        for (uint i = 0; i < n_bins; ++i)
            local_counts[i] = 0u;

        uint n_per_thread = n_particles / gl_NumWorkGroups.x;
        uint start_i = global_x * n_per_thread;
        uint end_i = min(start_i + n_per_thread, n_particles);

        for (uint i = start_i; i < end_i; ++i) {
            uint masked = (GET(pass, i) >> shift) & bitmask;
            local_counts[masked]++;
        }

        for (uint i = 0; i < n_bins; ++i)
            atomicAdd(global_counts[i], local_counts[i]);

        barrier();

        if (is_sequential_worker) {
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
}