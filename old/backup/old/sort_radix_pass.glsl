//
// sequentially radix sort an array of pairs by hash
//

// #define N_NUMBERS

layout(std430) buffer input_buffer {
    uint data_in[];
}; // size: N_NUMBERS

layout(std430) buffer output_buffer {
    uint data_out[];
}; // size: N_NUMBERS

shared uint global_counts[256];
shared uint i_to_masked[N_NUMBERS]; // cache masked values

shared uint masked_to_last_i[256];  // used to limit search range in scatter step
shared uint masked_to_first_i[256];

#define n_threads 256
layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
void computemain()
{
    uint thread_x = gl_GlobalInvocationID.y * 16 + gl_GlobalInvocationID.x;
    bool is_sequential_worker = thread_x == 0;

    const uint n_bins = 256;
    const uint bitmask = 0xFFu;

    uint n_per_thread = (N_NUMBERS + n_threads - 1) / n_threads;
    uint start = thread_x * n_per_thread;
    uint end = min(start + n_per_thread, N_NUMBERS);

    for (uint pass = 0; pass < 4; ++pass) {
        uint shift = 8 * pass;

        // init global counts

        if (thread_x < n_bins)
        {
            global_counts[thread_x] = 0u;
            masked_to_last_i[thread_x] = N_NUMBERS;
            masked_to_first_i[thread_x] = 0u;
        }

        barrier();

        // accumulate counts

        for (uint i = start; i < end; ++i) {
            uint masked = ((pass % 2 == 0 ? data_in[i] : data_out[i]) >> shift) & bitmask;
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
                data_out[count] = data_in[i];
            else
                data_in[count] = data_out[i];
        }

        barrier();
    }
}