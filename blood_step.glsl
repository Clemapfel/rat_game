//
// step particle simulation
//

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

struct CellMemoryMapping {
    uint n_particles;
    uint start_index; // start particle i
    uint end_index;   // end particle i
};

layout(std430) buffer cell_memory_mapping_buffer {
    CellMemoryMapping cell_memory_mapping[];
}; // size: n_columns * n_rows

layout(r32f) uniform readonly image2D density_texture;

uniform uint n_particles;
uniform float particle_radius;
uniform vec2 x_bounds; // left wall x, right wall x
uniform vec2 y_bounds; // top wall y, bottom wall y
uniform float delta;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with m, n were m * n <= n_particles
void computemain() {
    uint n_threads = gl_WorkGroupSize.x * gl_WorkGroupSize.y * gl_WorkGroupSize.z;
    uint thread_i = gl_GlobalInvocationID.x +
    gl_GlobalInvocationID.y * gl_NumWorkGroups.x +
    gl_GlobalInvocationID.z * gl_NumWorkGroups.x * gl_NumWorkGroups.y;

    uint n_particles_per_thread = uint(ceil(n_particles / float(n_threads)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; ++particle_i) {
        Particle particle = particles[particle_i];

        // calculate density gradient
        ivec2 position = ivec2(particle.position);
        float density_00 = imageLoad(density_texture, position + ivec2(-1, -1)).r;
        float density_01 = imageLoad(density_texture, position + ivec2( 0, -1)).r;
        float density_02 = imageLoad(density_texture, position + ivec2( 1, -1)).r;
        float density_10 = imageLoad(density_texture, position + ivec2(-1,  0)).r;
        float density_12 = imageLoad(density_texture, position + ivec2( 1,  0)).r;
        float density_20 = imageLoad(density_texture, position + ivec2(-1,  1)).r;
        float density_21 = imageLoad(density_texture, position + ivec2( 0,  1)).r;
        float density_22 = imageLoad(density_texture, position + ivec2( 1,  1)).r;

        float sobel_x = (density_02 + 2.0 * density_12 + density_22) - (density_00 + 2.0 * density_10 + density_20);
        float sobel_y = (density_20 + 2.0 * density_21 + density_22) - (density_00 + 2.0 * density_01 + density_02);

        vec2 gradient = vec2(sobel_x, sobel_y);
        particle.velocity = -1 * gradient * delta * 10;

        // Handle boundary conditions
        float min_x = x_bounds.x + particle_radius;
        float max_x = x_bounds.y - particle_radius;
        float min_y = y_bounds.x + particle_radius;
        float max_y = y_bounds.y - particle_radius;

        if (particle.position.x < min_x || particle.position.x > max_x) {
            particle.velocity.x *= -1;
        }

        if (particle.position.y < min_y || particle.position.y > max_y) {
            particle.velocity.y *= -1;
        }

        particle.position += particle.velocity * delta;
        particles[particle_i] = particle;
    }
}