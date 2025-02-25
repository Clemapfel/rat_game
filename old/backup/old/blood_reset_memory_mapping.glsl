//
// reset memory mapping to 0, separate from update_cell_hash shader because it does not need synchronization
//

struct CellMemoryMapping {
    uint n_particles;
    uint start_index; // start particle i
    uint end_index;   // end particle i
};

layout(std430) buffer cell_memory_mapping_buffer {
    CellMemoryMapping cell_memory_mapping[];
}; // size: n_columns * n_rows

uniform uint n_columns;
uniform uint n_rows;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with m, n, where m * n <= n_rows * n_columns
void computemain() {
    uint n_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint thread_i = gl_GlobalInvocationID.x +
        gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x +
        gl_GlobalInvocationID.z * gl_NumWorkGroups.x * gl_WorkGroupSize.x * gl_NumWorkGroups.y * gl_WorkGroupSize.y;

    uint n_cells = n_columns * n_rows;
    uint n_cells_per_thread = uint(ceil(n_cells / float(n_threads)));
    uint cell_start_i = thread_i * n_cells_per_thread;
    uint cell_end_i = min(cell_start_i + n_cells_per_thread, n_cells);

    for (uint cell_i = cell_start_i; cell_i < cell_end_i; ++cell_i) {
        CellMemoryMapping mapping = cell_memory_mapping[cell_i];
        mapping.n_particles = 0;
        mapping.start_index = 0;
        mapping.end_index = 0;
        cell_memory_mapping[cell_i] = mapping;
    }
}