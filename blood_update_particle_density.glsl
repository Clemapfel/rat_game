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

uniform uint n_particles;
uniform float particle_radius;
uniform float near_radius;
uniform float delta;

uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;
uniform float particle_mass = 1;

#define PI 3.1415926535897932384626433832795

float poly6_kernel(float dist, float radius) {
    if (dist > radius) return 0.0;
    return 315.0 / (64.0 * PI * pow(radius, 9)) * pow(radius * radius - dist * dist, 3);
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

    for (uint self_particle_i = particle_start_i; self_particle_i < particle_end_i; ++self_particle_i) {
        Particle self = particles_b[self_particle_i];
        vec2 self_position = self.position; // + delta * self.velocity;

        float density = 0.0;
        float near_density = 0.0;

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
                vec2 other_position = other.position; // + delta * other.velocity;
                float dist = distance(self_position, other_position);

                density += particle_mass * poly6_kernel(dist, particle_radius);
                near_density += particle_mass * poly6_kernel(dist, near_radius);
            }
        }

        self.density = density;
        self.near_density = near_density;
        particles_b[self_particle_i] = self;
    }
}