struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

struct ParticleOccupation {
    uint id;
    uint hash;
};

layout(std430) readonly buffer particle_occupation_buffer {
    ParticleOccupation particle_occupations[];
}; // size: n_particles

struct CellMemoryMapping {
    uint n_particles; // 0: invalid
    uint start_index;
    uint end_index;
};

layout(std430) readonly buffer cell_i_to_memory_mapping_buffer {
    CellMemoryMapping cell_i_to_memory_mapping[];
}; // size: n_rows * n_columns

uniform uint n_columns;
uniform uint n_rows;
uniform vec2 screen_size;

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

uint cell_xy_to_cell_linear_index(int cell_x, int cell_y) {
    return cell_y * n_columns + cell_x;
}

ivec2 cell_hash_to_cell_xy(uint cell_hash) {
    uint cell_x = cell_hash >> x_shift;
    uint cell_y = cell_hash & ((1u << x_shift) - 1u);
    return ivec2(cell_x, cell_y);
}

uniform uint thread_group_stride;

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint particle_i = gl_GlobalInvocationID.x;
    Particle self = particles[particle_i];

    // get own cell
    const uint n_cells = n_rows * n_columns;
    float cell_width = screen_size.x / float(n_columns);
    float cell_height = screen_size.y / float(n_rows);
    vec2 position = particles[particle_i].current_position;
    int center_cell_x = int(position.x / cell_width);
    int center_cell_y = int(position.y / cell_height);

    for (int cell_x = center_cell_x - 1; cell_x < center_cell_x + 1; ++cell_x)
    {
        for (int cell_y = center_cell_y - 1; cell_y < center_cell_y + 1; ++cell_y)
        {
            uint linear_index = cell_xy_to_cell_linear_index(center_cell_x, center_cell_y);
            CellMemoryMapping mapping = cell_i_to_memory_mapping[linear_index];

            if (mapping.n_particles == 0) continue;

            for (uint occupation_i = mapping.start_index; occupation_i < mapping.end_index; ++occupation_i) {
                ParticleOccupation other_occupation = particle_occupations[occupation_i];
                if (other_occupation.id == particle_i) continue;
            }
        }
    }

    particles[particle_i] = self;

    /*


    // velocity
    vec2 velocity = vec2(10, 0);

    // iterate other particles in cell neighborhood
    for (int cell_x = center_cell_x - 1; cell_x < center_cell_x + 1; cell_x++) {
        for (int cell_y = center_cell_y - 1; cell_x < center_cell_y + 1; cell_y++) {
            if (cell_x < 0 || cell_x > n_columns || cell_y < 0 || cell_y > n_rows)
                continue;

            uint linear_index = cell_xy_to_cell_linear_index(cell_x, cell_y);
            CellMemoryMapping mapping = cell_i_to_memory_mapping[linear_index];
            if (mapping.n_particles == 0)
                continue;

            for (uint occupation_i = mapping.start_index; occupation_i < mapping.end_index; ++occupation_i) {
                ParticleOccupation other_occupation = particle_occupations[occupation_i];
                Particle other_particle = particles[other_occupation.id];

                // particle interaction
                vec2 to_self = self.current_position - other_particle.current_position;
                float distance = length(to_self);
                float min_distance = self.radius + other_particle.radius;

                if (distance < min_distance && distance > 0.0) {
                    // Calculate repulsion force
                    vec2 repulsion = normalize(to_self) * (min_distance - distance);
                    //velocity += repulsion;
                }
            }
        }
    }

    // Update self's position based on velocity
    self.current_position += velocity;
    particles[particle_i] = self;
    */
}