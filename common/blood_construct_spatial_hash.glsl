//
// Iterate all particles, to compute their current cell
//

uniform uint n_particles;
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

layout(std430) writeonly buffer n_particles_per_cell_buffer {
    int n_particles_per_cell[];
}; // size: n_rows * n_columns

uniform uint n_rows;
uniform uint n_columns;
uniform uint n_particles;
uniform vec2 screen_size;

uint cell_xy_to_linear_index(uint cell_x, uint cell_y) {
    return cell_y * n_columns + cell_x;
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() // n_rows, n_columns invocations
{
    const uint n_cells = n_rows * n_columns;
    cell_width = screen_size.x / n_columns;
    cell_height = screen_size.y / n_rows;

    // get cell linear index and initialize valid cells
    uint linear_index = cell_xy_to_linear_index(
        uint(gl_GlobalInvocationID.x),
        uint(gl_GlobalInvocationID.y)
    );

    n_particles_per_cell[linear_index] = 0;

    // for each particle, write cell hash, to be sorted in the next step
    const uint x_shift = 16u;
    const uint y_shift = 0u;

    float n_particles_per_cell = ceil(float(n_particles) / float(n_cells));
    uint particle_start_i = uint(floor(float(linear_index) * n_particles_per_cell));
    for (uint particle_i = particle_start_i; particle_i < particle_start_i + n_particles_per_cell; ++particle_i) {
        vec2 position = particles[i].current_position;
        uint particle_cell_x = uint(position.x / cell_width);
        uint particle_cell_y = uint(position.y / cell_height);

        // write cell hash for each particle
        particle_occupations[particle_i].id = particle_i;
        particle_occupations[particle_i].hash = particle_cell_x << X_SHIFT | particle_cell_y << Y_SHIFT;

        // increment particles per cell counter
        atomicAdd(cell_is_valid[particle_i], 1);
    }
}