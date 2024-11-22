#define BUFFER_LAYOUT layout(std430)

#define CellHash uint
#define ParticleID uint

uniform uint n_particles;
struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

// particle id to particle
BUFFER_LAYOUT buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

// thread group to particle id
uniform int thread_group_stride = 1;
int thread_group_to_particle_id(int x, int y) {
    return y * thread_group_stride + x;
}

uniform int n_rows;
uniform int n_columns;
uniform vec2 screen_size;

const uint X_SHIFT = 16u;
const uint Y_SHIFT = 0u;
const uint CELL_INVALID_HASH = 0xFFFFFFFu;

BUFFER_LAYOUT buffer cell_occupation_buffer {
    ParticleID cell_occupation[];
}; // size: n_particles

// for each cell, xy-indexed, the start and end range for lookup of particles in that cell
struct CellOccupationMapping {
    uint start_i;
    uint end_i;
};

BUFFER_LAYOUT buffer cell_occupation_mapping_buffer {
    CellOccupationMapping cell_occupation_mapping[];
}; // size: n_rows * n_columns

const int CELL_IS_VALID = 1;
const int CELL_IS_INVALID = 0;

BUFFER_LAYOUT buffer cell_is_valid_buffer {
    int cell_is_valid_buffer[];
}; // size: n_rows * n_columns

int cell_xy_to_linear_index(int cell_x, int cell_y) {
    return cell_y * n_columns + cell_x ;
}

ivec2 thread_group_to_cell_xy(int x, int y) {
    return ivec2(x, y);
}

struct ParticleCellHashPair {
    ParticleID particle_id;
    CellHash cell_hash;
};

// for each particle, which cell it occupies
BUFFER_LAYOUT buffer particle_cell_pairs_buffer {
    ParticleCellHashPair particle_cell_pairs[];
}; // size: n_particles

BUFFER_LAYOUT buffer particle_cell_pairs_swap_buffer {
    ParticleCellHashPair particle_cell_pairs_swap[];
}; // size: n_particles

uniform uint bits_per_step = 8;
BUFFER_LAYOUT buffer shared_radix_counts_buffer {
    uint shared_radix_counts[];
}; // size 2^bits_per_step

BUFFER_LAYOUT buffer shader_radix_offsets_buffer {
    uint shared_radix_offsets[];
}; // size 2^bits_per_step

uniform int n_threads_x; // number of thread groups
uniform int n_threads_y;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    // get list of objects each thread operates on
    int thread_x = int(gl_GlobalInvocationID.x);
    int thread_y = int(gl_GlobalInvocationID.y);
    ivec2 particle_id_range = thread_group_to_particle_id_range(thread_x, thread_y);
    ivec2 cell_xy = thread_group_to_cell_xy(thread_x, thread_y);

    bool is_sequential_worker = thread_x == 1 && thread_y == 1;

    // initialize cell is valid
    uint cell_i = cell_xy_to_linear_index(cell_xy.x, cell_xy.y);
    cell_is_valid[cell_i] = CELL_IS_INVALID;

    // initialize cell occupation
    for (ParticleID id = particle_id_range.x; id < particle_id_range.y; ++id)
        particle_occupation_buffer[id] = id;

    barrier();

    // for each particle, get cell xy-coords, then hash
    for (ParticleID id = particle_id_range.x; id < particle_id_range.y; ++id)
    {
        Particle particle = particle_id_to_particle[id];
        uint cell_x = uint(particle.current_position.x / cell_width);
        uint cell_y = uint(particle.current_position.y / cell_height);
        uint cell_hash = cell_x << X_SHIFT | cell_y << Y_SHIFT;

        particle_id_to_cell_hash[particle_id].particle_id = particle_id;
        particle_id_to_cell_hash[particle_id].cell_hash = cell_hash;

        cell_is_valid_buffer[cell_xy_to_linear_index(cell_x, cell_y)] = CELL_IS_VALID;
    }

    barrier();

    // radix sort buffer based on cell hash

    const uint n_buckets = 1 << n_bits_per_step; // 2^n_bits_per_step
    uint counts[n_buckets];
    uint offsets[n_buckets];

    // sort pass #1
    for (pass = 0; pass < 32 / n_bits_per_step; ++pass)
    {
        for (int i = 0; i < n_buckets; ++i)
            counts[i] = 0;

        uint bitmask = 0xFFu << (pass * bits_per_step);

        // count occurrences in local buffer
        for (int i = particle_id_range.x; i < particle_id_range.y; ++i) {
            CellHash hash = particle_cell_pairs[i].cell_hash;
            uint masked = (hash & bitmask) << (pass * bits_per_step);
            counts[masked] += 1;
        }

        // accumulate in shared buffer
        for (int i = 0; i < n_buckets; ++i) {
            atomicAdd(shared_radix_counts[i], counts[i]);
        }

        barrier();

        // compute prefix sum sequentially
        // could be non-sequential: https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-39-parallel-prefix-sum-scan-cuda
        if (is_sequential_worker) {
            int sum = 0;
            for (int i = 0; i < n_buckets; ++i) {
                shared_radix_offsets[i] = sum;
                sum += shared_radix_counts[i];
            }
        }
        
        barrier();

        for (int i = particle_id_range.x; i < particle_id_range.y; ++i) {
            CellHash hash = particle_cell_pairs[i].cell_hash;
            uint masked = (hash & bitmask) << (pass * bits_per_step);
            particle_cell_pairs_swap[shared_radix_offsets[mask]] =
        }

    }




    barrier();

    // construct cell mapping from sorted buffer sequentially

    if (is_sequential_worker) {
        CellHash last_hash = CELL_INVALID_HASH;
        int n_particles_this_cell = 0;
        int current_start = 0;

        for (int i = 0; i < n_particles; ++i) {
            CellHash cell_hash = particle_cell_pairs[i].cell_hash;
            if (cell_hash != last_hash)
            {
                // get cell xy from hash
                uint cell_x = cell_hash | 0xFFFF0000u;
                uint cell_y = cell_hash | 0x0000FFFFu;
                int cell_i = cell_xy_to_linear_index(cell_x, cell_y);

                CellOccupationMapping mapping = cell_occupation_mapping[cell_i];
                mapping.start_i = current_start;
                mapping.end_i = current_start + n_particles_this_cell;

                n_particles_this_cell = 0;
                current_start = i;
                last_hash = cell_hash;
            }
            else {
                n_particles_this_cell += 1;
            }
        }
    } else return;
}

/*
 int n_threads = n_threads_x * n_threads_y;
    int start_i = int(round(float(n_particles) / float(n_threads)));
    CellHash hash = particle_cell_pairs[start_i].cell_hash;

    // scan to the right and left until transition to get range
    int right_i = start_i + 1;
    while (right_i < n_particles) {
        CellHash next_hash = particle_cell_pairs[right_i].cell_hash;
        if (next_hash != hash)
        break;

        right_i += 1;
    }

    int left_i = start_i - 1;
    while(left_i > 0) {
        CellHash next_hash = particle_cell_pairs[left_i].cell_hash;
        if (next_hash != hash)
        break;

        left_i -= 1;
    }

    // get cell xy from hash
    uint cell_x = hash | 0xFFFF0000u;
    uint cell_y = hash | 0x0000FFFFu;
    int cell_i = cell_xy_to_linear_index(cell_x, cell_y);

    //cell_occupation_mapping[cell_i].start_i = left_i;
    //cell_occupation_mapping[cell_i].end_i = right_i;

    atomicExchange(cell_occupation_mapping[cell_i].start_i, left_i);
    atomicExchange(cell_occupation_mapping[cell_i].end_i, right_i);
*/

/*
void particle_id_to_cell_occupation(ParticleID id) {
    Particle particle = particles[id];
    uint cell_x = uint(particle.current_position.x / cell_width);
    uint cell_y = uint(particle.current_position.y / cell_height);

    // linear index matrix of cells
    CellOccupationMapping occupation = cell_occupation_mapping[cell_y * n_columns + cell_x];

    for (uint i = occupation.start_i; i < occupation.end_i; ++i) {
        ParticleID other_id = cell_occupation[i];
        Particle other = particles[id];
        // treat particle here
    }
}
*/