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

layout(std430) buffer readonly cell_occupations_buffer {
    CellOccupation cell_occupations[];
};

layout(rgba32f) uniform readonly image2D density_texture; // x: density, zw: directional derivatives

const float h = 0.5;
float kernel_shape(float x) {
    return exp(-2 * (x - h)) / (exp(h) * sinh(h));
}

float alt_kernel(float x) {
    if (abs(x) > h)
    return 0;

    if (x >= 0)
        return kernel_shape(x);
    else
        return kernel_shape(1 - x - 1);
}

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

uniform float delta = 1 / 120;
uniform float particle_radius;
uniform uint n_particles;
uniform vec4 bounds;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;

ivec2 position_to_cell_xy(vec2 position) {
    return ivec2(position.x / cell_width, position.y / cell_height);
}

uint cell_xy_to_cell_linear_index(ivec2 xy) {
    return xy.y * n_columns + xy.x;
}

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
void computemain() {

    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint particles_per_thread = (n_particles + total_threads - 1) / total_threads;

    uint particle_start_i = global_thread_id * particles_per_thread;
    uint particle_end_i = min(particle_start_i + particles_per_thread, n_particles);

    float radius = particle_radius;
    float min_x = bounds.x + radius;
    float max_x = bounds.x + bounds.z - radius;
    float min_y = bounds.y + radius;
    float max_y = bounds.y + bounds.w - radius;

    const float sim_delta = 1 / (60 * 2);
    const float pressure_multiplier = 2000;
    const float target_density = 1;
    float smoothing_radius = particle_radius * 2;

    float density = 0;
    float near_density = 0;
    float square_smoothing_radius = smoothing_radius * smoothing_radius;

    // update pressure

    for (uint self_particle_i = particle_start_i; self_particle_i < particle_end_i; ++self_particle_i) {
        Particle self = particles_b[self_particle_i];
        vec2 self_position = self.position + delta * self.velocity;

        vec4 self_density_data = imageLoad(density_texture, ivec2(self_position));
        float self_density = self_density_data.x;

        vec2 pressure_force = vec2(0);

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
                vec2 other_position = other.position + delta * other.velocity;
                vec4 other_density_data = imageLoad(density_texture, ivec2(other_position));
                float other_density = other_density_data.x;

                pressure_force += normalize(self_position - other_position) * alt_kernel(distance(self_position, other_position) / (2 * particle_radius));
            }
        }

        self.velocity += pressure_multiplier * pressure_force * delta;
        particles_b[self_particle_i] = self;
    }

    const float gravity_scale = 0;
    const float restitution_scale = 1;
    const vec2 gravity = vec2(0, 1);

    for (uint i = particle_start_i; i < particle_end_i; ++i) {
        Particle particle = particles_b[i];

        // apply external forces
        particle.velocity += gravity * gravity_scale * delta;

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