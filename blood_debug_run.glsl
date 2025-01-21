struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) buffer particle_buffer_a {
    Particle particles_a[];
}; // size: n_particles

layout(std430) buffer particle_buffer_b {
    Particle particles_b[];
}; // size: n_particles

struct CellOccupation {
    uint start_i;
    uint end_i;
};

layout(std430) buffer cell_occupations_buffer { // todo: make writeonly
    CellOccupation cell_occupations[];
};

uniform uint n_particles;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;

layout(std430) buffer global_counts_buffer {
    uint global_counts[];
}; // size: n_columns * n_rows

layout(std430) buffer is_sorted_buffer {
    uint is_sorted[];
}; // size: n_columns * n_rows

uint position_to_cell_linear_index(vec2 position) {
    uint cell_x = uint(position.x / float(cell_width));
    uint cell_y = uint(position.y / float(cell_height));
    return cell_y * n_columns + cell_x;
}

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    if (gl_GlobalInvocationID.x + gl_GlobalInvocationID.y + gl_GlobalInvocationID.z != 0) return;

    // update particle id
    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_a[i];
        particle.cell_id = position_to_cell_linear_index(particle.position);
        particles_a[i] = particle;
    }

    // reset counts and occupation
    for (uint i = 0; i < n_rows * n_columns; ++i) {
        cell_occupations[i] = CellOccupation(0, 0);
        global_counts[i] = 0;
    }

    // accumulate counts
    for (uint i = 0; i < n_particles; ++i)
        atomicAdd(global_counts[particles_a[i].cell_id], 1u);

    // prefix sum
    for (uint i = 1; i < n_rows * n_columns; ++i)
        global_counts[i] += global_counts[i-1];

    // scatter
    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_a[i];
        uint new_position = atomicAdd(global_counts[particle.cell_id], -1);
        particles_b[new_position - 1] = particle;
    }

    // verify
    bool sorted = true;
    for (uint i = 0; i < n_particles - 1; ++i) {
        Particle current = particles_b[i];
        Particle next = particles_b[i+1];
        if (current.cell_id > next.cell_id) {
            sorted = false;
            break;
        }
    }

    is_sorted[0] = sorted ? 1u : 0u;

    // construct occupations
    uint start_i = 0;
    uint current = particles_b[0].cell_id;
    for (uint i = 1; i < n_particles; ++i) {
        uint next = particles_b[i].cell_id;
        if (next != current) {
            cell_occupations[current] = CellOccupation(
                start_i,
                i // exclusive
            );

            start_i = i;
            current = next;
        }
    }

    cell_occupations[current] = CellOccupation(
        start_i,
        n_particles + 1
    );
}

