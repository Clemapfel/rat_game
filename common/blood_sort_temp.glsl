#define BUFFER_LAYOUT layout(std430)

uniform uint n_bits_per_step = 8;

struct Pair {
    uint id;
    uint hash;
};

BUFFER_LAYOUT buffer elements_in_buffer {
    uint elements_in[];
};

BUFFER_LAYOUT buffer elements_out_buffer {
    uint elements_out[];
};

#define N_BINS 256
shared uint shared_counts[N_BINS];
shared uint shared_offsets[N_BINS];

uniform int n_numbers; // count of numbers to sort

#define GET(pass, i) pass % 2 == 0 ? elements_in[i] : elements_out[i]
layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    int thread_x = int(gl_GlobalInvocationID.x);
    int thread_y = int(gl_GlobalInvocationID.y);

    const int n_buckets = 256; // 2^n_bits_per_step
    uint counts[n_buckets];
    uint offsets[n_buckets];

    for (int pass = 0; pass < int(32 / n_bits_per_step); ++pass)
    {
        // initialize local counts
        for (int i = 0; i < n_buckets; ++i) {
            counts[i] = 0;
        }

        uint bitmask = ((1u << n_bits_per_step) - 1u) << (pass * n_bits_per_step);

        // count occurrences in local buffer
        for (int i = 0; i < n_numbers; ++i) {
            uint hash = GET(pass, i);
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            counts[masked] += 1;
        }

        // accumulate in shared buffer
        for (int i = 0; i < n_buckets; ++i) {
            shared_counts[i] += counts[i];
        }

        // prefix sum
        uint sum = 0;
        for (int i = 0; i < n_buckets; ++i) {
            shared_offsets[i] = sum;
            sum += shared_counts[i];
        }

        // Copy the results to shared_offsets
        if (thread_x < n_buckets) {
            shared_offsets[thread_x] = shared_counts[thread_x];
        }

        // reset counts
        if (thread_x < n_buckets)
            shared_counts[thread_x] = 0u;

        // reorder
        for (int old_index = 0; old_index < n_numbers; ++old_index) {
            uint hash = GET(pass, old_index);
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            uint new_index = atomicAdd(shared_offsets[masked], 1);

            if (pass % 2 == 0)
            elements_out[new_index] = elements_in[old_index];
            else
            elements_in[new_index] = elements_out[old_index];
        }
    }
}