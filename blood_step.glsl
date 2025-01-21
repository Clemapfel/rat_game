struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) buffer particle_buffer_a {
    Particle particles_a[];
};

layout(std430) buffer particle_buffer_b {
    Particle particles_b[];
};

struct CellOccupation {
    uint start_i;
    uint end_i;
};

layout(std430) buffer readonly cell_occupations_buffer {
    CellOccupation cell_occupations[];
};

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

const float sim_delta = 1 / (60 * 2);
const float target_density = 4.0;
const float gravity_scale = 1000;
const float restitution_scale = 0.3;
const float friction = 0.1;
const float mass = 1.0;
const float pressure_strength = 3000;
const float viscosity_strength = 3000;
float smoothing_radius = particle_radius * 4;


const float eps = 0.0001;

// Density kernel (Poly6)
float density_kernel(float dist) {
    if (dist > smoothing_radius) return 0.0;
    float scale = 315.0 / (64.0 * 3.14159 * pow(smoothing_radius, 9));
    float v = smoothing_radius * smoothing_radius - dist * dist;
    return scale * v * v * v;
}

// Pressure kernel gradient (Spiky)
vec2 pressure_kernel_gradient(vec2 r, float dist) {
    if (dist > smoothing_radius || dist < eps) return vec2(0);
    float scale = -45.0 / (3.14159 * pow(smoothing_radius, 6)) *
    pow(smoothing_radius - dist, 2);
    return r * (scale / dist);
}

// Viscosity kernel laplacian
float viscosity_kernel_laplacian(float dist) {
    if (dist > smoothing_radius) return 0.0;
    return 45.0 / (3.14159 * pow(smoothing_radius, 6)) * (smoothing_radius - dist);
}

void handle_collision(inout vec2 position, inout vec2 velocity) {

    // Left boundary
    if (position.x < bounds.x + particle_radius) {
        position.x = bounds.x + particle_radius + eps;
        if (velocity.x < 0.0) {
            float normal_component = velocity.x;
            float tangent_component = velocity.y;

            velocity.x = -normal_component * restitution_scale;
            velocity.y = tangent_component * (1.0 - friction);
        }
    }

    // Right boundary
    if (position.x > bounds.z - particle_radius) {
        position.x = bounds.z - particle_radius - eps;
        if (velocity.x > 0.0) {
            float normal_component = velocity.x;
            float tangent_component = velocity.y;

            velocity.x = -normal_component * restitution_scale;
            velocity.y = tangent_component * (1.0 - friction);
        }
    }

    // Top boundary
    if (position.y < bounds.y + particle_radius) {
        position.y = bounds.y + particle_radius + eps;
        if (velocity.y < 0.0) {
            float normal_component = velocity.y;
            float tangent_component = velocity.x;

            velocity.y = -normal_component * restitution_scale;
            velocity.x = tangent_component * (1.0 - friction);
        }
    }

    // Bottom boundary
    if (position.y > bounds.w - particle_radius) {
        position.y = bounds.w - particle_radius - eps;
        if (velocity.y > 0.0) {
            float normal_component = velocity.y;
            float tangent_component = velocity.x;

            velocity.y = -normal_component * restitution_scale;
            velocity.x = tangent_component * (1.0 - friction);
        }
    }
}

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

    // Update pressure, density, and viscosity
    for (uint self_particle_i = particle_start_i; self_particle_i < particle_end_i; ++self_particle_i) {
        Particle self = particles_b[self_particle_i];
        vec2 self_position = self.position + delta * self.velocity;

        float density = 0.0;
        vec2 pressure_force = vec2(0);
        vec2 viscosity_force = vec2(0);

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

                vec2 r = self_position - other_position;
                float dist = length(r);

                // density
                density += mass * density_kernel(dist);

                // pressure
                float pressure = pressure_strength * (density - target_density);
                float other_pressure = pressure_strength * (density - target_density);
                float shared_pressure = (pressure + other_pressure) * 0.5;

                if (dist < smoothing_radius) {
                    // pressure force
                    pressure_force += mass * shared_pressure * pressure_kernel_gradient(r, dist);

                    // viscosity force
                    vec2 velocity_diff = other.velocity - self.velocity;
                    viscosity_force += viscosity_strength * mass * velocity_diff * viscosity_kernel_laplacian(dist);
                }
            }
        }

        self.velocity += ((pressure_force + viscosity_force) / max(density, eps)) * delta;
        particles_b[self_particle_i] = self;
    }

    // Apply external forces and handle collisions
    const vec2 gravity = vec2(0, 1);
    for (uint i = particle_start_i; i < particle_end_i; ++i) {
        Particle particle = particles_b[i];

        particle.velocity += gravity * gravity_scale * delta;
        particle.position += particle.velocity * delta;

        handle_collision(particle.position, particle.velocity);
        particles_a[i] = particle;
    }
}