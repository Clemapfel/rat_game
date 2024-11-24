#define BUFFER_LAYOUT layout(std430)

BUFFER_LAYOUT buffer elements_in_buffer {
    uint elements_in[];
};

BUFFER_LAYOUT buffer elements_out_buffer {
    uint elements_out[];
};

#define N_BINS 256
#define BITS_PER_STEP 8

uniform int n_numbers; // count of numbers to sort

#define GET(pass, i) pass % 2 == 0 ? elements_in[i] : elements_out[i]

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    if (gl_GlobalInvocationID.x != 0) return; // sic, this shader runs fully sequentially

    uint counts[N_BINS];
    uint offsets[N_BINS];

    for (int pass = 0; pass < 32 / BITS_PER_STEP; ++pass)
    {
        for (int i = 0; i < N_BINS; ++i) {
            counts[i] = 0;
            offsets[i] = 0;
        }

        uint bitmask = 0x000000FF << (pass * BITS_PER_STEP);

        for (int i = 0; i < n_numbers; ++i) {
            uint x = GET(pass, i);
            uint mask = (x & bitmask) >> (pass * BITS_PER_STEP);
            counts[mask] += 1;
        }

        uint sum = 0;
        for (int i = 0; i < n_numbers; ++i) {
            offsets[i] = sum;
            sum = sum + counts[i];
        }

        for (int i = 0; i < n_numbers; ++i) {
            uint x = GET(pass, i);
            uint mask = (x & bitmask) >> (pass * BITS_PER_STEP);

            if (pass % 2 == 0)
                elements_out[offsets[mask]] = x;
            else
                elements_in[offsets[mask]] = x;

            offsets[mask] += 1;
        }
    }
}