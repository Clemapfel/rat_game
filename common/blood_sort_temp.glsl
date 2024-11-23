

#define BUFFER_LAYOUT layout(std430)

uniform uint n_bits_per_step = 8;

struct Pair {
    uint id;
    uint hash;
};

BUFFER_LAYOUT buffer to_sort_buffer {
    Pair to_sort_a[];
};

BUFFER_LAYOUT buffer to_sort_swap_buffer {
    Pair to_sort_b[];
};

#define N_BINS 256
shared uint shared_counts[N_BINS];
shared uint shared_offsets[N_BINS];

uniform int n_threads_x; // number of thread groups
uniform int n_threads_y;
uniform int n_numbers; // count of numbers to sort

// get index range for each thread
ivec2 get_index_range(int thread_x, int thread_y) {
    float n_threads = n_threads_x * n_threads_y;
    int linear_index = thread_y * n_threads_x + thread_x;
    int n_per_thread = int(ceil(n_numbers / n_threads));
    int start = clamp(int((linear_index / n_threads) * n_numbers), 0, n_numbers);
    int end = clamp(start + n_per_thread, 0, n_numbers);
    return ivec2(start, end);
}

layout (local_size_x = 16) in;
void computemain()
{
    int thread_x = int(gl_GlobalInvocationID.x);
    int thread_y = int(gl_GlobalInvocationID.y);
    ivec2 index_range = get_index_range(thread_x, thread_y);

    bool is_sequential_worker = thread_x == 0 && thread_y == 0;

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
            uint hash = pass % 2 == 0 ? to_sort_a[i].hash : to_sort_b[i].hash;
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
        // TODO: make parallel https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-39-parallel-prefix-sum-scan-cuda
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
            uint hash = pass % 2 == 0 ? to_sort_a[old_index].hash : to_sort_b[old_index].hash;
            uint masked = (hash & bitmask) >> (pass * n_bits_per_step);
            uint new_index = atomicAdd(shared_offsets[masked], 1);

            if (pass % 2 == 0)
                to_sort_b[new_index] = to_sort_a[old_index];
            else
                to_sort_a[new_index] = to_sort_b[old_index];
        }

        barrier();

        // trade swap and to_sort
        if (pass % 2 == 0)
            for (int i = index_range.x; i < index_range.y; ++i)
                to_sort_a[i] = to_sort_b[i];
        else
            for (int i = index_range.x; i < index_range.y; ++i)
                to_sort_b[i] = to_sort_a[i];

        barrier();
    }
}