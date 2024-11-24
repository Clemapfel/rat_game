//#define WORKGROUP_SIZE 256
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

// get index range for each thread
ivec2 get_index_range(int thread_x) {
    int n_per_thread =
    if (thread_x == 0)
        return ivec2(0, n_numbers);
    else
        return ivec2(0, -1);

    /*
    int n_per_thread = int(n_numbers);
    int start = thread_x;
    int end = clamp(start + n_per_thread, 0, n_numbers);
    return ivec2(start, end);
    */
}

#define GET(pass, i) pass % 2 == 0 ? elements_in[i] : elements_out[i]

layout (local_size_x = WORKGROUP_SIZE, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    int thread_x = int(gl_GlobalInvocationID.x);
    int thread_y = int(gl_GlobalInvocationID.y);
    ivec2 index_range = get_index_range(thread_x);

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
        for (int i = index_range.x; i < index_range.y; ++i) {
            uint hash = GET(pass, i);
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            counts[masked] += 1;
        }

        barrier();

        // accumulate in shared buffer
        for (int i = 0; i < n_buckets; ++i) {
            atomicAdd(shared_counts[i], counts[i]);
        }

        barrier();

        // parallel prefix sum (Blelloch scan)
        for (int d = 1; d < n_buckets; d *= 2) {
            int index = (thread_x + 1) * d * 2 - 1;
            if (index < n_buckets) {
                shared_counts[index] += shared_counts[index - d];
            }
            barrier();
        }

        if (thread_x == 0 && thread_y == 0) {
            shared_counts[n_buckets - 1] = 0;
        }

        barrier();

        for (int d = n_buckets / 2; d > 0; d /= 2) {
            int index = (thread_x + 1) * d * 2 - 1;
            if (index < n_buckets) {
                uint temp = shared_counts[index];
                shared_counts[index] += shared_counts[index - d];
                shared_counts[index - d] = temp;
            }
            barrier();
        }

        // Copy the results to shared_offsets
        if (thread_x < n_buckets) {
            shared_offsets[thread_x] = shared_counts[thread_x];
        }

        barrier();

        // reset counts
        if (thread_x < n_buckets)
            shared_counts[thread_x] = 0u;

        barrier();

        // reorder in swap
        for (int old_index = index_range.x; old_index < index_range.y; ++old_index) {
            uint hash = GET(pass, old_index);
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            uint new_index = atomicAdd(shared_offsets[masked], 1);

            if (pass % 2 == 0)
            elements_out[new_index] = elements_in[old_index];
            else
            elements_in[new_index] = elements_out[old_index];
        }

        barrier();
    }
}