//
// radix sort particles by cell hash
//

#ifndef N_PARTICLES
    #error "N_PARTICLES undefined"
#endif

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) buffer particle_buffer_a {
    Particle particles_a[];
}; // size: n_particles

layout(std430) buffer particle_buffer_b {
    Particle particles_b[];
}; // size: n_particles

shared uint global_counts[256];
shared uint i_to_masked[N_PARTICLES]; // cache masked values

shared uint masked_to_last_i[256];  // used to limit search range in scatter step
shared uint masked_to_first_i[256];

/*
layout(std430) buffer is_sorted_buffer {
    uint is_sorted[];
};
*/

#define n_threads 256

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in; // dispatch with 1, 1
void computemain()
{
    uint thread_x = gl_GlobalInvocationID.y * 16 + gl_GlobalInvocationID.x;
    bool is_sequential_worker = thread_x == 0;

    const uint n_bins = 256;
    const uint bitmask = 0xFFu;

    uint n_per_thread = (N_PARTICLES + n_threads - 1) / n_threads;
    uint start = thread_x * n_per_thread;
    uint end = min(start + n_per_thread, N_PARTICLES);

    for (uint pass = 0; pass < 4; ++pass) {
        uint shift = 8 * pass;

        // init global counts

        if (thread_x < n_bins)
        {
            global_counts[thread_x] = 0u;
            masked_to_last_i[thread_x] = N_PARTICLES;
            masked_to_first_i[thread_x] = 0u;
        }

        barrier();

        // accumulate counts

        for (uint i = start; i < end; ++i) {
            uint value = (pass % 2 == 0 ? particles_a[i].cell_hash : particles_b[i].cell_hash);
            uint masked = (value >> shift) & bitmask;
            i_to_masked[i] = masked;
            atomicMin(masked_to_first_i[masked], i);
            atomicMax(masked_to_last_i[masked], i + 1);
            atomicAdd(global_counts[masked], 1u);
        }

        barrier();

        // parallel prefix sum (blelloch scan)

        for (uint offset = 1; offset < n_bins; offset *= 2) {
            uint index = (thread_x + 1) * offset * 2 - 1;
            if (index < n_bins) {
                global_counts[index] += global_counts[index - offset];
            }
            barrier();
        }

        if (is_sequential_worker) {
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

        // scatter only if masked matches thread, this way only one thread operates on each global_counts element

        uint max_i = masked_to_last_i[thread_x];
        uint min_i = masked_to_first_i[thread_x];
        for (uint i = min_i; i < max_i; ++i) {
            uint masked = i_to_masked[i];
            if (masked != thread_x) continue;

            uint count = global_counts[masked]++;
            if (pass % 2 == 0)
                particles_b[count] = particles_a[i];
            else
                particles_a[count] = particles_b[i];
        }

        barrier();
    }

    /*
    if (is_sequential_worker) {
        bool sorted = true;
        for (uint i = 0; i < N_PARTICLES - 1; ++i) {
            Particle a = particles_a[i];
            Particle b = particles_a[i+1];
            if (a.cell_hash > b.cell_hash) {
                sorted = false;
                break;
            }
        }
        is_sorted[0] = sorted ? uint(-1) : 0u;
    }
    */
}