layout(std430) buffer global_counts_buffer {
    uint global_counts[];
};

#ifndef LOCAL_SIZE
#   define LOCAL_SIZE 256
#endif

uniform uint n_rows;
uniform uint n_columns;

layout (local_size_x = LOCAL_SIZE, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    uint thread_id = gl_LocalInvocationID.x;
    uint n_bins = n_rows * n_columns;

    // Up-sweep phase (reduce)
    for (uint stride = 1; stride < n_bins; stride *= 2) {
        uint index = (thread_id + 1) * stride * 2 - 1;

        if (index < n_bins) {
            global_counts[index] += global_counts[index - stride];
        }

        barrier();
    }

    // Clear last element
    if (thread_id == 0) {
        global_counts[n_bins - 1] = 0;
    }

    barrier();

    // Down-sweep phase
    for (uint stride = n_bins / 2; stride > 0; stride /= 2) {
        uint index = (thread_id + 1) * stride * 2 - 1;

        if (index < n_bins) {
            uint temp = global_counts[index];
            global_counts[index] += global_counts[index - stride];
            global_counts[index - stride] = temp;
        }

        barrier();
    }
}