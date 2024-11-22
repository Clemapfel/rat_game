#define BUFFER_LAYOUT layout(std430)

uniform uint n_bits_per_step = 8;

struct Pair {
    uint id;
    uint hash;
};

BUFFER_LAYOUT buffer to_sort_buffer {
    Pair to_sort[];
};

BUFFER_LAYOUT buffer to_sort_swap_buffer {
    Pair to_sort_swap[];
};

BUFFER_LAYOUT buffer shared_counts_buffer {
    uint shared_counts[];
};

BUFFER_LAYOUT buffer shared_offsets_buffer {
    uint shared_offsets[];
};

uniform int n_threads_x; // number of thread groups
uniform int n_threads_y;
uniform int n_numbers; // count of numbers to sort

// get index range for each thread
ivec2 get_index_range(int thread_x, int thread_y) {
    int linear_index = thread_y * n_threads_x + thread_x;
    int n_per_thread = int(ceil(n_numbers / float(n_threads_x * n_threads_y)));
    int start = clamp(linear_index * n_per_thread, 0, n_numbers);
    int end = clamp(start + n_per_thread, 0, n_numbers);
    return ivec2(start, end);
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    int thread_x = int(gl_GlobalInvocationID.x);
    int thread_y = int(gl_GlobalInvocationID.y);
    ivec2 index_range = get_index_range(thread_x, thread_y);

    bool is_sequential_worker = thread_x == 0 && thread_y == 0;

    const int n_buckets = 256; // 2^n_bits_per_step
    uint counts[n_buckets];
    uint offsets[n_buckets];

    int n_passes = int(32 / n_bits_per_step);
    for (int pass = 0; pass < n_passes; ++pass)
    {
        // initialize local counts
        for (int i = 0; i < n_buckets; ++i) {
            counts[i] = 0;
        }

        uint bitmask = (1u << n_bits_per_step) - 1u;
        bitmask <<= (pass * n_bits_per_step);

        // count occurrences in local buffer
        for (int i = index_range.x; i < index_range.y; ++i) {
            uint hash = to_sort[i].hash;
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            counts[masked] += 1;
        }

        barrier();

        // accumulate in shared buffer
        for (int i = 0; i < n_buckets; ++i) {
            atomicAdd(shared_counts[i], counts[i]);
        }

        barrier();

        // sequentially compute prefix sum
        if (is_sequential_worker) {
            uint sum = 0;
            for (int i = 0; i < n_buckets; ++i) {
                shared_offsets[i] = sum;
                sum += shared_counts[i];
                shared_counts[i] = 0; // Reset shared_counts for next pass
            }
        }

        barrier();

        // reorder in swap
        for (int old_index = index_range.x; old_index < index_range.y; ++old_index) {
            uint hash = to_sort[old_index].hash;
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            uint new_index = atomicAdd(shared_offsets[masked], 1);
            to_sort_swap[new_index] = to_sort[old_index];
        }

        barrier();

        // trade swap and to_sort
        for (int i = index_range.x; i < index_range.y; ++i) {
            to_sort[i] = to_sort_swap[i];
        }

        barrier();
    }
}