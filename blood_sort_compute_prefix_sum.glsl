
layout(std430) buffer global_counts_buffer {
    uint global_counts[];
};

uniform uint n_rows;
uniform uint n_columns;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with 1, 1
void computemain()
{
    if (gl_GlobalInvocationID.x != 0) return;
    uint n_bins = n_rows * n_columns;
    for (uint i = 1; i < n_bins; ++i) {
        global_counts[i] += global_counts[i - 1];
    }
}