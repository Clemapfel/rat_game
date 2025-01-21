struct Particle {
    vec2 position;
    vec2 velocity;
    float mass;
    uint cell_id;
};

layout(std430) buffer particle_buffer_a {
    Particle particles_a[];
};

layout(std430) buffer particle_buffer_b {
    Particle particles_b[];
};

uniform float delta = 1 / 120;
uniform uint n_particles;

uniform vec2 center;
uniform float force_direction = 1;
uniform float force_scale = 100;
uniform float max_distance = 100;

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
void computemain() {
    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint particles_per_thread = (n_particles + total_threads - 1) / total_threads;

    uint particle_start_i = global_thread_id * particles_per_thread;
    uint particle_end_i = min(particle_start_i + particles_per_thread, n_particles);

    for (uint i = particle_start_i; i < particle_end_i; ++i) {
        Particle particle = particles_b[i];

        vec2 to_center = center - particle.position;
        float distance = length(to_center);

        float weight = exp(-1 * (distance / max_distance));
        //weight = -1 * tanh(1 - distance / max_distance);
        particle.velocity += normalize(to_center) * weight * force_scale;
        particles_b[i] = particle;
    }
}