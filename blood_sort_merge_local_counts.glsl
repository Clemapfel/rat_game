//
// sum up all threadgroups' local counts
//

layout(std430) writeonly buffer global_counts_buffer {
    uint global_counts[];
}; // size: n_columns * n_rows

struct CellOccupation {
    uint start_i;
    uint end_i;
    uint n_particles;
};

layout(std430) buffer cell_occupations_buffer { // TODO: make write only
    CellOccupation cell_occupations[];
};

layout(r32ui) uniform readonly uimage2D local_counts_texture;
uniform uint n_rows;
uniform uint n_columns;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with sqrt(n_rows, n_columns)
void computemain()
{


    uint n_counts = n_columns * n_rows;
    uvec3 thread_ns = gl_NumWorkGroups * gl_WorkGroupSize;
    uint n_threads = thread_ns.x * thread_ns.y * thread_ns.z;

    uint thread_i = gl_GlobalInvocationID.x +
        gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x +
        gl_GlobalInvocationID.z * gl_NumWorkGroups.x * gl_WorkGroupSize.x *
        gl_NumWorkGroups.y * gl_WorkGroupSize.y;

    uint n_per_thread = uint(ceil(n_counts / float(n_threads)));

    uint start_i = thread_i * n_per_thread;
    uint end_i = min(start_i + n_per_thread, n_counts);

    uint n_texture_rows = imageSize(local_counts_texture).y;

    // sum local counts and write to buffer
    for (uint i = start_i; i < end_i; ++i) {
        uint column_sum = 0;
        for (uint row_i = 0; row_i < n_texture_rows; ++row_i)
            column_sum += imageLoad(local_counts_texture, ivec2(i, row_i)).r;

        global_counts[i] = column_sum;
        cell_occupations[i].n_particles = column_sum;
    }
}