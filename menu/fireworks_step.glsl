struct Particle {
    vec3 position;
    vec3 direction;
    vec3 velocity;
    float hue;
    float value;
    float mass;
    uint group_id;
    uint mode;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

struct ParticleGroup {
    vec3 start;
    vec3 end;
};

layout(std430) buffer readonly group_buffer {
    ParticleGroup groups[];
}; // size: n_groups

uniform uint n_groups;
uniform uint n_particles_per_group;
uint n_particles = n_groups * n_particles_per_group;

uniform float delta;

const uint MODE_ASCEND = 0;
const uint MODE_EXPLODE = 1;

uniform float particle_radius;
uniform float gravity_factor = 200;
uniform float ascend_boost_velocity = 1000; //100;
uniform float explode_initial_velocity = 500;
uniform float explode_velocity = 100;
const float particle_mass_decay = 0.3;
const float min_mass = 0.1;
const float particle_value_decay = 2;
uniform float value_decay_mass_threshold = 0.2;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint n_particles = n_groups * n_particles_per_group;
    uint particles_per_thread = (n_particles + total_threads - 1) / total_threads;

    uint start_i = global_thread_id * particles_per_thread;
    uint end_i = min(start_i + particles_per_thread, n_particles);

    const vec3 gravity = vec3(0, 1, 0) * gravity_factor;

    for (uint particle_i = start_i; particle_i < end_i; ++particle_i) {
        Particle particle = particles[particle_i];
        if (particle.value <= 0)
            continue;

        if (particle.mode == MODE_ASCEND) {
            ParticleGroup group = groups[particle.group_id];
            vec3 direction = group.end - particle.position;
            particle.velocity += normalize(direction) * ascend_boost_velocity * delta;

            if (distance(particle.position, group.end) <= particle_radius) {
                particle.mode = MODE_EXPLODE;
                particle.velocity = normalize(particle.direction) * explode_initial_velocity;
            }

            particle.position += particle.velocity * delta;
        }
        else if (particle.mode == MODE_EXPLODE) {
            particle.velocity += normalize(particle.direction) * explode_velocity * delta;
            particle.velocity += gravity * delta * dot(normalize(particle.direction), normalize(particle.velocity));
            particle.mass = max(particle.mass - particle_mass_decay * delta, min_mass);

            if (particle.mass < value_decay_mass_threshold)
                particle.value = max(particle.value - particle_value_decay * delta, 0);

            particle.position += particle.mass * particle.velocity * delta;
        }

        particles[particle_i] = particle;
    }
}