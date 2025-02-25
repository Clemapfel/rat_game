//
// Iterate all particles, to compute their current cell
//

struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

layout(std430) buffer readonly particle_buffer {
    Particle particles[];
}; // size: n_particles

struct ParticleOccupation {
    uint id;
    uint hash;
};

layout(std430) writeonly buffer particle_occupation_buffer {
    ParticleOccupation particle_occupations[];
}; // size: n_particles

uniform uint n_rows;
uniform uint n_columns;
uniform uint n_particles;
uniform vec2 screen_size;

uint cell_xy_to_linear_index(uint cell_x, uint cell_y) {
    return cell_y * n_columns + cell_x;
}

uint cell_xy_to_cell_hash(uint cell_x, uint cell_y) {
    return cell_x << 16u | cell_y << 0u;
}

ivec2 cell_hash_to_cell_xy(uint cell_hash) {
    uint cell_x = cell_hash >> 16u;
    uint cell_y = cell_hash & ((1u << 16u) - 1u);
    return ivec2(int(cell_x), int(cell_y));
}

float cell_width = screen_size.x / n_columns;
float cell_height = screen_size.y / n_rows;

uvec2 position_to_xy(vec2 position) {
    return uvec2(position.x / cell_width, position.y / cell_height);
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() // n_columns, n_rows invocations
{
    const uint n_cells = n_rows * n_columns;

    // get cell linear index and initialize valid cells
    uint cell_linear_index = cell_xy_to_linear_index(
        uint(gl_GlobalInvocationID.x),
        uint(gl_GlobalInvocationID.y)
    );

    // distribute particles per thread, where number of threads is equal to number of cells
    uint particle_count_per_thread = uint(ceil(float(n_particles) / float(n_cells)));
    uint particle_start_i = cell_linear_index * particle_count_per_thread;
    uint particle_end_i = clamp(particle_start_i + particle_count_per_thread, 0, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; ++particle_i) {
        vec2 position = particles[particle_i].current_position;
        uvec2 particle_cell_xy = position_to_cell_xy(position);

        // write cell hash for each particle
        particle_occupations[particle_i].id = particle_i;
        particle_occupations[particle_i].hash = cell_xy_to_cell_hash(particle_cell_x, particle_cell_y);
    }
}