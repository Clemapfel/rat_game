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

layout(std430) buffer cell_occupations_buffer { // TODO: make write only
    CellOccupation cell_occupations[];
};

layout(rgba32f) uniform readonly image2D density_texture; // x: density, zw: directional derivatives

uniform uint n_particles;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;
uniform float particle_radius;
uniform vec4 bounds;
uniform float delta = 1 / 120;

const ivec2 directions[9] = ivec2[](
    ivec2(+0, +0),
    ivec2(+0, -1),
    ivec2(+1, +0),
    ivec2(+0, +1),
    ivec2(-1, +0),
    ivec2(+1, -1),
    ivec2(+1, +1),
    ivec2(-1, +1),
    ivec2(-1, -1)
);

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

ivec2 position_to_cell_xy(vec2 position) {
    return ivec2(position.x / cell_width, position.y / cell_width);
}

uint cell_xy_to_cell_linear_index(ivec2 xy) {
    return xy.y * n_rows + xy.x;
}

// density kernels

#define PI 3.1415926535897932384626433832795
const float smoothing_radius = 60;
const float K_SpikyPow3 = 15.0 / (PI * pow(smoothing_radius, 6));
const float K_SpikyPow2 = 45.0 / (PI * pow(smoothing_radius, 6));

float near_density_kernel(float dist, float radius)
{
    if (dist < radius)
    {
        float v = radius - dist;
        return v * v * v * K_SpikyPow3;
    }
    return 0.0;
}

float density_kernel(float dist, float radius)
{
    if (dist < radius)
    {
        float v = radius - dist;
        return v * v * K_SpikyPow2;
    }
    return 0.0;
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
    uint current_id = particles_b[0].cell_id;
    for (uint i = 1; i < n_particles; ++i) {
        uint current = particles_b[i].cell_id;
        uint next = particles_b[i+1].cell_id;

        if (current != next) {
            cell_occupations[current_id] = CellOccupation(
                start_i,
                i
            );

            start_i = i;
            current_id = next;
        }
    }

    // step

    const ivec2 directions[9] = ivec2[](
        ivec2(+0, +0),
        ivec2(+0, -1),
        ivec2(+1, +0),
        ivec2(+0, +1),
        ivec2(-1, +0),
        ivec2(+1, -1),
        ivec2(+1, +1),
        ivec2(-1, +1),
        ivec2(-1, -1)
    );

    float radius = particle_radius;
    float min_x = bounds.x + radius;
    float max_x = bounds.x + bounds.z - radius;
    float min_y = bounds.y + radius;
    float max_y = bounds.y + bounds.w - radius;

    const float sim_delta = 1 / (60 * 2);
    const float pressure_multiplier = 100;
    const float target_pressure = 0;

    float density = 0;
    float near_density = 0;
    float square_smoothing_radius = smoothing_radius * smoothing_radius;

    // update pressure
    vec2 pressure_force = vec2(0);

    for (uint self_particle_i = 0; self_particle_i < n_particles; ++self_particle_i) {
        Particle self = particles_b[self_particle_i];
        vec2 self_position = self.position + delta * self.velocity;
        vec4 self_pressure_data = imageLoad(density_texture, ivec2(self_position));
        float self_pressure = self_pressure_data.x * pressure_multiplier;
        vec2 self_pressure_derivative = self_pressure_data.zw * pressure_multiplier;

        ivec2 center_xy = position_to_cell_xy(self.position);
        for (uint direction_i = 0; direction_i < 9; direction_i++) {
            ivec2 cell_xy = center_xy + directions[direction_i];

            if (cell_xy.x < 0 || cell_xy.y < 0 || cell_xy.x > n_columns || cell_xy.y > n_rows)
                continue;

            CellOccupation occupation = cell_occupations[cell_xy_to_cell_linear_index(cell_xy)];
            for (uint other_particle_i = occupation.start_i; other_particle_i < occupation.end_i; ++other_particle_i) {
                if (other_particle_i == self_particle_i)
                    continue;

                Particle other = particles_b[other_particle_i];
                vec2 neighbor_position = self.position + delta * self.velocity;
                float distance_to_neighbor = length(self_position - neighbor_position);

                if (distance_to_neighbor * distance_to_neighbor > square_smoothing_radius)
                    continue;

                vec4 neighbor_pressure_data = imageLoad(density_texture, ivec2(neighbor_position));
                float neighbor_pressure = neighbor_pressure_data.x;
                vec2 neighbor_pressure_derivative = neighbor_pressure_data.zw;
                float shared_pressure = (self_pressure + neighbor_pressure) / 2;

                pressure_force += normalize(self_position - neighbor_position) * neighbor_pressure_derivative * shared_pressure / neighbor_pressure;
            }
        }

        vec2 acceleration = pressure_force / self_pressure;
        self.velocity = -1 * normalize(self_pressure_derivative);
        particles_b[self_particle_i] = self;
    }

    const float gravity_scale = 20;
    const float restitution_scale = 0.5;

    const vec2 gravity = vec2(0, 1);

    for (uint i = 0; i < n_particles; ++i) {
        Particle particle = particles_b[i];

        // apply external forces
        //particle.velocity += gravity * gravity_scale * delta;

        // check bounds
        if (particle.position.x < min_x) {
            particle.position.x = min_x;
            particle.velocity.x = -restitution_scale * particle.velocity.x;
        } else if (particle.position.x > max_x) {
            particle.position.x = max_x;
            particle.velocity.x = -restitution_scale * particle.velocity.x;
        }

        if (particle.position.y < min_y) {
            particle.position.y = min_y;
            particle.velocity.y = -restitution_scale * particle.velocity.y;
        } else if (particle.position.y > max_y) {
            particle.position.y = max_y;
            particle.velocity.y = -restitution_scale * particle.velocity.y;
        }

        // move
        particle.position += particle.velocity * delta;
        particles_a[i] = particle;
    }
}

