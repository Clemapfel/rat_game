//
// sequentially radix sort an array of pairs by hash
//

layout(std430) buffer input_buffer {
    uint data_in[];
}; // size: n_numbers

layout(std430) buffer output_buffer {
    uint data_out[];
}; // size: n_numbers

layout(std430) buffer global_counts_buffer {
    uint global_counts[];
}; // size: 256

uniform uint n_numbers;
uniform uint pass;

#define GET(pass, i) (pass % 2 == 0 ? data_in[i] : data_out[i])

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    if (!(gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0))
        return;

    const uint n_bins = 256;
    const uint bitmask = 0xFFu;
    uint shift = 8 * pass;

    for (uint i = 0; i < n_bins; ++i)
        global_counts[i] = 0u;

    for (uint i = 0; i < n_numbers; ++i) {
        uint masked = (GET(pass, i) >> shift) & bitmask;
        global_counts[masked]++;
    }

    uint sum = 0u;
    for (uint i = 0; i < n_bins; ++i) {
        uint count = global_counts[i];
        global_counts[i] = sum;
        sum += count;
    }

    for (uint i = 0; i < n_numbers; ++i) {
        uint masked = (GET(pass, i) >> shift) & bitmask;

        if (pass % 2 == 0)
            data_out[global_counts[masked]] = data_in[i];
        else
            data_in[global_counts[masked]] = data_out[i];

        global_counts[masked]++;
    }
}