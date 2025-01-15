//
// write particle cell hash
//

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

layout(std430) buffer cell_memory_mapping_buffer {
    CellMemoryMapping cell_memory_mapping[];
}; // size: n_columns * n_rows

uniform uint n_particles;
uniform float particle_radius;
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

#ifndef LOCAL_SIZE_X
    #define LOCAL_SIZE_X 32
#endif

#ifndef LOCAL_SIZE_Y
    #define LOCAL_SIZE_Y 32
#endif

ivec2 neighbors[9] = ivec2[](
    ivec2(+0, +1),  // Top-center
    ivec2(+1, +1),  // Top-right
    ivec2(+1, +0),  // Right-center
    ivec2(+1, -1),  // Bottom-right
    ivec2(+0, -1),  // Bottom-center
    ivec2(-1, -1),  // Bottom-left
    ivec2(-1, +0),  // Left-center
    ivec2(-1, +1),  // Top-left
    ivec2(+0, +0)   // Center
);

layout (local_size_x = LOCAL_SIZE_X, local_size_y = LOCAL_SIZE_Y, local_size_z = 1) in; // dispatch with 1, 1
void computemain() {
    uint thread_i = gl_LocalInvocationID.y * LOCAL_SIZE_X + gl_LocalInvocationID.x;
    uint n_particles_per_thread = uint(ceil(n_particles / float(LOCAL_SIZE_X * LOCAL_SIZE_Y)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; ++particle_i) {
        Particle particle = particles[particle_i];
        ivec2 center_xy = position_to_cell_xy(particle.position);
        vec2 particle_xy = particle.position;

        particles[particle_i].cell_hash = cell_xy_to_cell_hash(center_xy);

        // center cell always occupied
        atomicAdd(cell_memory_mapping[cell_xy_to_cell_i(center_xy)].n_particles, 1u);

        // check neighboring cells
        float particle_right_x = particle_xy.x + particle_radius;
        float particle_left_x = particle_xy.x - particle_radius;
        float particle_bottom_y = particle_xy.y + particle_radius;
        float particel_top_y = particle_xy.y - particle_radius;

        for (uint offset_i = 0; offset_i < 8; ++offset_i) {
            ivec2 offset = neighbors[offset_i];
            ivec2 current_xy = center_xy + offset;

            float left_x = current_xy.x * cell_width;
            float right_x = left_x + cell_width;
            float top_y = current_xy.y * cell_height;
            float bottom_y = top_y + cell_height;

            if (
                (particle_right_x > left_x && particle_left_x < right_x) &&
                (particle_bottom_y > top_y && particel_top_y < bottom_y)
            ) {
                atomicAdd(cell_memory_mapping[cell_xy_to_cell_i(current_xy)].n_particles, 1u);
            }
        }
    }
}
