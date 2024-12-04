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

uniform uint n_particles;
//uniform uint pass; // [0, 3)

shared uint global_counts[256];
shared uint mask_locks[256];

#define GET(pass, i) (pass % 2 == 0 ? particle_occupations[i].hash : swap[i].hash)

#define n_threads 256
layout (local_size_x = n_threads, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    uint thread_x = gl_GlobalInvocationID.x;
    bool is_sequential_worker = thread_x == 0;
    const uint n_bins = 256;
    const uint bitmask = 0xFFu;

    uint n_per_thread = uint(ceil(n_particles / float(n_threads)));
    uint start = thread_x * n_per_thread;
    uint end = min(start + n_per_thread, n_particles);

    if (thread_x < n_bins)
        mask_locks[thread_x] = 0u;

    for (uint pass = 0; pass < 4; pass++) {
        uint shift = 8 * pass;

        // init counts

        if (thread_x < n_bins)
            global_counts[thread_x] = 0u;

        barrier();

        // accumulate counts

        for (uint i = start; i < end; ++i) {
            uint masked = (GET(pass, i) >> shift) & bitmask;
            atomicAdd(global_counts[masked], 1u);
        }

        barrier();

        // parallel prefix sum (blelloch)

        for (uint offset = 1; offset < n_bins; offset *= 2) {
            uint index = (thread_x + 1) * offset * 2 - 1;
            if (index < n_bins) {
                global_counts[index] += global_counts[index - offset];
            }
            barrier();
        }

        if (thread_x == 0) {
            global_counts[n_bins - 1] = 0;
        }

        barrier();

        for (uint offset = n_bins / 2; offset > 0; offset /= 2) {
            uint index = (thread_x + 1) * offset * 2 - 1;
            if (index < n_bins) {
                uint temp = global_counts[index];
                global_counts[index] += global_counts[index - offset];
                global_counts[index - offset] = temp;
            }
            barrier();
        }

        barrier();

        // reorder sequentially
        if (is_sequential_worker) {
            for (uint i = 0; i < n_particles; ++i) {
                uint masked = (GET(pass, i) >> shift) & bitmask;
                uint count = global_counts[masked];
                if (pass % 2 == 0)
                    swap[count] = particle_occupations[i];
                else
                    particle_occupations[count] = swap[i];

                global_counts[masked]++;
            }
        }

        barrier();
    }
}