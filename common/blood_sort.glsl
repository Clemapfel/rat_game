//
// sequentially radix sort an array of pairs by hash
//

struct ParticleOccupation {
    uint id;
    uint hash;
};

layout(std430) buffer particle_occupation_buffer {
    ParticleOccupation occupations[];
}; // size: n_particles

layout(std430) buffer particle_occupation_swap_buffer {
    ParticleOccupation swap[];
}; // size: n_particles

uniform uint n_numbers;

#define GET(pass, i) (pass % 2 == 0 ? occupations[i].hash : swap[i].hash)

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() // 1, 1 invocations
{
    if (!(gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0))
        return;

    const uint n_bins = 256;
    const uint bitmask = 0xFFu;
    uint counts[n_bins];

    for (uint pass = 0u; pass < 4u; pass++)
    {
        uint shift = 8 * pass;

        for (uint i = 0; i < n_bins; ++i)
            counts[i] = 0u;

        for (uint i = 0; i < n_numbers; ++i) {
            uint masked = (GET(pass, i) >> shift) & bitmask;
            counts[masked]++;
        }

        uint sum = 0u;
        for (uint i = 0; i < n_bins; ++i) {
            uint count = counts[i];
            counts[i] = sum;
            sum += count;
        }

        for (uint i = 0; i < n_numbers; ++i) {
            uint masked = (GET(pass, i) >> shift) & bitmask;

            if (pass % 2 == 0)
                swap[counts[masked]] = occupations[i];
            else
                occupations[counts[masked]] = swap[i];

            counts[masked]++;
        }
    }
}