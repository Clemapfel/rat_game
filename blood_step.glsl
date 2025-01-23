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
uniform float particle_mass = 100;
uniform vec4 bounds;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;
uniform float particle_radius;
uniform float near_radius;

const float target_density = 10.0;
const float target_near_density = 2 * target_density;
const float restitution_scale = 0.0;
const float friction = 0.1;
const float gravity_scale = 20;
const float pressure_strength = 20;
const float near_pressure_strength = pressure_strength * 4;
const float viscosity_strength = pressure_strength * 0.2;
const float buoyancy_strength = -0.0;
const float velocity_damping = 0.996;

const float eps = 0.0001;
#define PI 3.1415926535897932384626433832795

vec2 pressure_kernel_gradient(vec2 r, float dist) {
    if (dist > particle_radius || dist < eps) return vec2(0);
    float scale = -45.0 / (PI * pow(particle_radius, 6)) * pow(particle_radius - dist, 2);
    return r * (scale / dist);
}

vec2 near_pressure_kernel_gradient(vec2 r, float dist) {
    if (dist > near_radius || dist < eps) return vec2(0);
    float scale = -45.0 / (PI * pow(near_radius, 6)) * pow(near_radius - dist, 2);
    return r * (scale / dist);
}

float viscosity_kernel_laplacian(float dist) {
    if (dist > particle_radius) return 0.0;
    return 45.0 / (PI * pow(particle_radius, 6)) * (particle_radius - dist);
}

ivec2 position_to_cell_xy(vec2 position) {
    return ivec2(position.x / cell_width, position.y / cell_height);
}

uint cell_xy_to_cell_linear_index(ivec2 xy) {
    return xy.y * n_columns + xy.x;
}

float density_to_pressure(float density) {
    return pressure_strength * (density - target_density);
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

                // Combined pressure forces
                float pressure = density_to_pressure(self.density);
                float near_pressure = density_to_pressure(other.near_density);

                float other_pressure = density_to_pressure(other.density);
                float other_near_pressure = density_to_pressure(other.near_density);

                float shared_pressure = (pressure + other_pressure) * 0.5;
                float shared_near_pressure = (near_pressure + other_near_pressure) * 0.5;

                if (dist < particle_radius) {
                    pressure_force += particle_mass * shared_pressure * pressure_kernel_gradient(r, dist);
                    near_pressure_force += particle_mass * shared_near_pressure * near_pressure_kernel_gradient(r, dist);

                    vec2 velocity_diff = other.velocity - self.velocity;
                    viscosity_force += viscosity_strength * particle_mass * velocity_diff * viscosity_kernel_laplacian(dist);
                }
            }
        }

        vec2 total_force = pressure_force + viscosity_force + near_pressure_force;
        self.velocity += (total_force / max(self.density, eps)) * delta;
        particles_b[self_particle_i] = self;
    }

    // Apply external forces and handle collisions
    const vec2 gravity = vec2(0, 1);
    for (uint i = particle_start_i; i < particle_end_i; ++i) {
        Particle particle = particles_b[i];
        vec2 velocity = particle.velocity;
        vec2 position = particle.position;

        vec2 gravity_force = gravity * particle_mass - vec2(0, max(target_density - particle.density, 0)) * buoyancy_strength;
        velocity += gravity_scale * max(gravity_force, 0) * delta;
        position += velocity * delta * velocity_damping;

        // left
        if (position.x < bounds.x + particle_radius) {
            position.x = bounds.x + particle_radius + eps;
            if (velocity.x < 0.0) {
                float normal_component = velocity.x;
                float tangent_component = velocity.y;
                velocity.x = -normal_component * restitution_scale;
                //velocity.y = tangent_component * (1.0 - friction);
            }
        }

        // right
        if (position.x > bounds.z - particle_radius) {
            position.x = bounds.z - particle_radius - eps;
            if (velocity.x > 0.0) {
                float normal_component = velocity.x;
                float tangent_component = velocity.y;
                velocity.x = -normal_component * restitution_scale;
                //velocity.y = tangent_component * (1.0 - friction);
            }
        }

        // top
        if (position.y < bounds.y + particle_radius) {
            position.y = bounds.y + particle_radius + eps;
            if (velocity.y < 0.0) {
                float normal_component = velocity.y;
                float tangent_component = velocity.x;
                velocity.y = -normal_component * restitution_scale;
                //velocity.x = tangent_component * (1.0 - friction);
            }
        }

        // bottom
        if (position.y > bounds.w - particle_radius) {
            position.y = bounds.w - particle_radius - eps;
            if (velocity.y > 0.0) {
                float normal_component = velocity.y;
                float tangent_component = velocity.x;
                velocity.y = -normal_component * restitution_scale;
                //velocity.x = tangent_component * (1.0 - friction);
            }
        }

        particle.position = position;
        particle.velocity = velocity;
        particles_a[i] = particle;
    }
}