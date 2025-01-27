//
// step particle simulation
//

struct Particle {
    vec2 position;
    vec2 velocity;
    float density;
    float near_density;
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

uniform float delta;
uniform uint n_particles;
uniform float particle_mass = 1000;
uniform vec4 bounds;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;
uniform float particle_radius;
uniform float near_radius;

layout(rgba32f) uniform readonly image2D sdf_texture; // xy: gradient, z: distance, w: sign

const float target_density = 4.0;
const float target_near_density = target_density;
const float restitution_scale = 0.0;
const float friction = 0.1;
const float gravity_scale = 1.7;
const float pressure_strength = 1;
float near_pressure_strength = pressure_strength * 2;
const float viscosity_strength = pressure_strength * 0.17;
const float hitbox_strength = 8;
const float velocity_damping = 0.996;
const float max_velocity = 500;

const float eps = 0.0001;
const float max_gradient = 2;
#define PI 3.1415926535897932384626433832795

vec2 spiky_kernel_gradient(vec2 r_vec, float h) {
    float r = length(r_vec);
    if (r >= h || r <= 0)
        return vec2(0.0);

    float sigma = -45.0 / (PI * pow(h, 6.0));
    vec2 res = (sigma * pow(h - r, 2.0) * (r_vec / r));
    if (length(res) > max_gradient)
        return normalize(res) * max_gradient;
    else
        return res;
}

float viscosity_kernel_laplacian(float dist, float radius) {
    if (dist > radius) return 0.0;
    return 45.0 / (PI * pow(radius, 6)) * (radius - dist);
}

ivec2 position_to_cell_xy(vec2 position) {
    return ivec2(position.x / cell_width, position.y / cell_height);
}

uint cell_xy_to_cell_linear_index(ivec2 xy) {
    return xy.y * n_columns + xy.x;
}

float density_to_pressure(float density, float strength) {
    return strength * (density - target_density);
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

        vec2 pressure_force = vec2(0);
        vec2 near_pressure_force = vec2(0);
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

                float pressure = density_to_pressure(self.density, pressure_strength);
                float other_pressure = density_to_pressure(other.density, pressure_strength);

                float near_pressure = density_to_pressure(self.near_density, near_pressure_strength);
                float other_near_pressure = density_to_pressure(other.near_density, near_pressure_strength);

                float shared_pressure = (pressure + other_pressure) * 0.5;
                float shared_near_pressure = (near_pressure + other_near_pressure) * 0.5;

                if (dist < particle_radius) {
                    pressure_force += particle_mass * shared_pressure * spiky_kernel_gradient(r, particle_radius);
                    near_pressure_force += particle_mass * shared_near_pressure * spiky_kernel_gradient(r, near_radius);
                    vec2 velocity_diff = other.velocity - self.velocity;
                    viscosity_force += viscosity_strength * particle_mass * velocity_diff * viscosity_kernel_laplacian(dist, particle_radius);
                }
            }
        }

        vec2 total_force = pressure_force + near_pressure_force + viscosity_force;
        self.velocity += (total_force / max(self.density, eps)) * delta;
        particles_b[self_particle_i] = self;
    }

    // Apply external forces and handle collisions
    const vec2 gravity = vec2(0, 1);
    for (uint i = particle_start_i; i < particle_end_i; ++i) {
        Particle particle = particles_b[i];
        vec2 velocity = particle.velocity;
        vec2 position = particle.position;

        // object collision
        velocity += -1 * imageLoad(sdf_texture, ivec2(round(position))).xy * hitbox_strength;

        // rk4
        vec2 k1_velocity = gravity * particle_mass;
        vec2 k1_position = velocity;

        vec2 k2_velocity = gravity * particle_mass;
        vec2 k2_position = velocity + 0.5 * k1_velocity * delta;

        vec2 k3_velocity = gravity * particle_mass;
        vec2 k3_position = velocity + 0.5 * k2_velocity * delta;

        vec2 k4_velocity = gravity * particle_mass;
        vec2 k4_position = velocity + k3_velocity * delta;

        velocity += (k1_velocity + 2.0 * k2_velocity + 2.0 * k3_velocity + k4_velocity) / 6.0 * delta * gravity_scale;
        position += (k1_position + 2.0 * k2_position + 2.0 * k3_position + k4_position) / 6.0 * delta * velocity_damping;

        // prevent particles from leaving spatial hash area
        position.x = clamp(position.x, bounds.x + particle_radius + eps, bounds.z - particle_radius - eps);
        position.y = clamp(position.y, bounds.y + particle_radius + eps, bounds.w - particle_radius - eps);

        particle.position = position;
        particle.velocity = min(velocity, max_velocity);
        particles_a[i] = particle;
    }
}