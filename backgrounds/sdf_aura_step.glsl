
struct Particle {
    vec2 position;
    vec2 velocity;
    float radius;
    float radius_velocity;
    vec3 color;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform uint n_particles;
uniform vec4 bounds;
uniform float max_radius;
uniform float min_radius;
uniform float delta;

#define LOCAL_SIZE_X 8
layout (local_size_x = LOCAL_SIZE_X, local_size_y = LOCAL_SIZE_X, local_size_z = 1) in;
void computemain() {

    uint thread_i = gl_LocalInvocationID.y * LOCAL_SIZE_X + gl_LocalInvocationID.x;
    uint n_particles_per_thread = uint(ceil(n_particles / float(LOCAL_SIZE_X * LOCAL_SIZE_X)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; particle_i++) {
        Particle particle = particles[particle_i];

        float radius = particle.radius;
        float min_x = bounds.x + radius;
        float max_x = bounds.x + bounds.z - radius;
        float min_y = bounds.y + radius;
        float max_y = bounds.y + bounds.w - radius;

        particle.position += particle.velocity * delta;

        if (particle.position.x < min_x) {
            particle.position.x = min_x;
            particle.velocity.x = -particle.velocity.x;
        } else if (particle.position.x > max_x) {
            particle.position.x = max_x;
            particle.velocity.x = -particle.velocity.x;
        }

        if (particle.position.y < min_y) {
            particle.position.y = min_y;
            particle.velocity.y = -particle.velocity.y;
        } else if (particle.position.y > max_y) {
            particle.position.y = max_y;
            particle.velocity.y = -particle.velocity.y;
        }

        particle.radius += particle.radius_velocity * delta;

        if (particle.radius > max_radius) {
            particle.radius = max_radius;
            particle.radius_velocity *= -1;
        }
        else if (particle.radius < min_radius) {
            particle.radius = min_radius;
            particle.radius_velocity *= -1;
        }

        particles[particle_i] = particle;
    }
}