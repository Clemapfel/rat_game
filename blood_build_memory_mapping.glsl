struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

struct CellMemoryMapping {
    uint n_particles;
    uint start_index; // start particle i
    uint end_index;   // end particle i
};

layout(std430) buffer writeonly cell_memory_mapping_buffer {
    CellMemoryMapping cell_memory_mapping[];
}; // size: n_columns * n_rows

uniform uint n_particles;
uniform vec2 screen_size;
uniform uint n_columns;
uniform uint n_rows;
uniform float cell_width;
uniform float cell_height;


ivec2 position_to_cell_xy(vec2 xy) {
    int cell_x = int(floor(xy.x / cell_width));
    int cell_y = int(floor(xy.y / cell_height));
    return ivec2(cell_x, cell_y);
}

uint cell_xy_to_cell_hash(ivec2 cell_xy) {
    return uint(cell_xy.x) << 16u | uint(cell_xy.y) << 0u;
}

ivec2 cell_hash_to_cell_xy(uint hash) {
    int x = int(hash >> 16u);
    int y = int(hash & 0xFFFFu);
    return ivec2(x, y);
}

uint cell_xy_to_cell_i(ivec2 cell_xy) {
    return cell_xy.y * n_rows + cell_xy.x;
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint current_hash = -1;
    uint start_i = 0;
    bool should_update_hash = true;

    for (uint particle_i = 0; particle_i < n_particles; ++particle_i) {
        Particle particle = particles[particle_i];
        ivec2 center_xy = position_to_cell_xy(particle.position);
        vec2 particle_xy = particle.position;
        particles[particle_i].cell_hash = cell_xy_to_cell_hash(center_xy);

        if (should_update_hash) {
            current_hash = particle.cell_hash;
            start_i = particle_i;
            should_update_hash = false;
        }

        if (particle.cell_hash != current_hash) {
            cell_memory_mapping[cell_xy_to_cell_i(center_xy)] = CellMemoryMapping(
                particle_i - start_i,
                start_i,
                particle_i
            );

            should_update_hash = true;
        }
    }
}
