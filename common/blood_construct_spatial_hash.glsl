//
// build cell to particle id map by scanning for transitions in sorted occupation mapping
//

struct ParticleOccupation {
    uint id;
    uint hash;
};

layout(std430) readonly buffer particle_occupation_buffer {
    ParticleOccupation particle_occupations[];
}; // size: n_particles

struct CellMemoryMapping {
    uint is_valid;
    uint start_index;
    uint end_index;
};

layout(std430) writeonly buffer cell_i_to_memory_mapping_buffer {
    CellMemoryMapping cell_i_to_memory_mapping[];
}; // size: n_rows * n_columns

uniform uint n_rows;
uniform uint n_columns;
uniform uint n_particles;

uniform int n_threads_x;
uniform int n_threads_y;

const uint x_shift = 16u;
const uint y_shift = 0u;

uint cell_xy_to_cell_hash(uint cell_x, uint cell_y) {
    return cell_x << x_shift | cell_y << y_shift;
}

uint cell_hash_to_cell_linear_index(uint cell_hash) {
    uint cell_x = cell_hash >> x_shift;
    uint cell_y = cell_hash & ((1u << x_shift) - 1u);
    return cell_y * n_columns + cell_x;
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() // 1, 1 invocations
{
    uint thread_x = uint(gl_GlobalInvocationID.x);
    uint thread_y = uint(gl_GlobalInvocationID.y);

    // equally distribute parts of the scan range among each thread
    uint thread_linear_index = thread_y * n_threads_y + thread_x;
    uint n_elements_per_thread = uint(ceil(n_particles / (n_threads_x * n_threads_y)));

    uint start_i = thread_linear_index * n_elements_per_thread;
    uint end_i = clamp(start_i + n_elements_per_thread, 0, n_particles);

    // scan range for cell hash transitions, if one is found, create new cell entry
    // intentionally goes 1 past the start and end to catch transitions between thread blocks
    const uint n_cells = n_rows * n_columns;
    for (uint i = clamp(start_i - 1, 0, n_cells); i < clamp(end_i + 1, 0, n_cells); ++i)
    {
        ParticleOccupation current = particle_occupations[i+0];
        ParticleOccupation next = particle_occupations[i+1];

        if (current.hash != next.hash) {
            uint current_i = cell_hash_to_cell_linear_index(current.hash);
            atomicExchange(cell_i_to_memory_mapping[current_i].end_index, i);

            uint next_i = cell_hash_to_cell_linear_index(next.hash);
            atomicExchange(cell_i_to_memory_mapping[next_i].start_index, i);
        }
    }
}