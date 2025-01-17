//
// for all particles, write cell id based on current particle position
//

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

uniform uint n_particles;
uniform float delta;
uniform float particle_radius;
uniform vec4 bounds;

#ifndef LOCAL_SIZE_X
    #define LOCAL_SIZE_X 32
#endif

#ifndef LOCAL_SIZE_Y
    #define LOCAL_SIZE_Y 32
#endif

layout (local_size_x = LOCAL_SIZE_X, local_size_y = LOCAL_SIZE_Y, local_size_z = 1) in; // dispatch with sqrt(n_particles) / LOCAL_SIZE_X, sqrt(n_particles) / LOCAL_SIZE_Y
void computemain()
{
    uint thread_i = gl_LocalInvocationID.y * gl_WorkGroupSize.x + gl_LocalInvocationID.x;
    uint n_particles_per_thread = uint(ceil(n_particles / float(gl_WorkGroupSize.x * gl_WorkGroupSize.y)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    float radius = particle_radius;
    float min_x = bounds.x + radius;
    float max_x = bounds.x + bounds.z - radius;
    float min_y = bounds.y + radius;
    float max_y = bounds.y + bounds.w - radius;

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; particle_i++) {
        Particle particle = particles_in[particle_i];
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

        particles_out[particle_i] = particle;
    }
}