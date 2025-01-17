struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) buffer particle_buffer_in {
    Particle particles_in[];
}; // size: n_particles

layout(std430) buffer particle_buffer_out {
    Particle particles_out[];
}; // size: n_particles

struct CellOccupation {
    uint start_i;
    uint end_i;
};

layout(std430) buffer cell_occupations_buffer { // TODO: make write only
    CellOccupation cell_occupations[];
};

uniform uint n_particles;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;
uniform float particle_radius;
uniform vec4 bounds;
uniform float delta;

layout(std430) buffer global_counts_buffer {
    uint global_counts[];
}; // size: n_columns * n_rows

layout(std430) buffer is_sorted_buffer {
    uint is_sorted[];
}; // size: n_columns * n_rows

uint position_to_cell_linear_index(vec2 position) {
    uint cell_x = uint(position.x / cell_width);
    uint cell_y = uint(position.y / cell_height);
    return cell_y * n_rows + cell_x;
}

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    if (gl_GlobalInvocationID.x + gl_GlobalInvocationID.y + gl_GlobalInvocationID.z != 0) return;

    // update particle id
    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_in[i];
        particle.cell_id = position_to_cell_linear_index(particle.position);
        particles_in[i] = particle;
    }

    // reset counts
    for (uint i = 0; i < n_rows * n_columns; ++i)
        global_counts[i] = 0;

    // accumulate counts
    for (uint i = 0; i < n_particles; ++i)
        atomicAdd(global_counts[particles_in[i].cell_id], 1u);

    // prefix sum
    for (uint i = 1; i < n_rows * n_columns; ++i)
        global_counts[i] += global_counts[i-1];

    // scatter
    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_in[i];
        uint new_position = atomicAdd(global_counts[particle.cell_id], -1);
        particles_out[new_position - 1] = particle;
    }

    // verify
    bool sorted = true;
    for (uint i = 0; i < n_particles - 1; ++i) {
        Particle current = particles_out[i];
        Particle next = particles_out[i+1];
        if (current.cell_id > next.cell_id) {
            sorted = false;
            break;
        }
    }

    is_sorted[0] = sorted ? 1u : 0u;

    // construct occupation
    uint start_i = 0;
    uint current_id = particles_out[start_i].cell_id;
    for (uint i = 0; i < n_rows * n_columns - 1; ++i) {
        uint current = particles_out[i].cell_id;
        uint next = particles_out[i+1].cell_id;
        if (current != next) {
            cell_occupations[current] = CellOccupation(
                start_i,
                i
            );

            current_id = next;
            start_i = i + 1;
        }
    }

    // step
    float radius = particle_radius;
    float min_x = bounds.x + radius;
    float max_x = bounds.x + bounds.z - radius;
    float min_y = bounds.y + radius;
    float max_y = bounds.y + bounds.w - radius;

    for (uint i = 0; i < n_particles; ++i) {

        Particle particle = particles_out[i];
        particle.position += particle.velocity * delta;

        if (particle.position.x < min_x) {
            particle.position.x = min_x;
            particle.velocity.x = -1 * particle.velocity.x;
        } else if (particle.position.x > max_x) {
            particle.position.x = max_x;
            particle.velocity.x = -1 * particle.velocity.x;
        }

        if (particle.position.y < min_y) {
            particle.position.y = min_y;
            particle.velocity.y = -1 * particle.velocity.y;
        } else if (particle.position.y > max_y) {
            particle.position.y = max_y;
            particle.velocity.y = -1 * particle.velocity.y;
        }

        particles_in[i] = particle;
    }
}

