struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform uint n_particles;

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

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() {}