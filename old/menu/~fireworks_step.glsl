struct Particle {
    vec3 position;
    vec3 direction;
    vec3 velocity;
    float hue;
    float value;
    float mass;
    uint group_id;
};

layout(std430) buffer readonly particle_buffer_a {
    Particle particles_a[];
}; // size: n_particles

layout(std430) buffer writeonly particle_buffer_b {
    Particle particles_b[];
}; // size: n_particles

uniform uint n_groups;
uniform uint n_particles_per_group;
uniform float delta;
uniform float elapsed;

const uint PARTICLE_GROUP_MODE_ASCEND = 0;
const uint PARTICLE_GROUP_MODE_SPREAD = 1;
const uint PARTICLE_GROUP_MODE_BURN_OUT = 2;

struct ParticleGroup {
    vec2 start;
    vec2 end;
    uint mode;
};

layout(std430) buffer readonly group_buffer {
    ParticleGroup groups[];
}; // size: n_groups

layout(std430) buffer writeonly fade_out_buffer {
    float fade_out[];
}; // size: 1

const float gravity_factor = 75;
const float mass_decay = 0.3;
const float value_decay = mass_decay * 0.8;
const float boost_duration = 1;
const float boost_velocity = 500;
const float friction_coefficient = 0.98; // Friction coefficient
const float air_resistance = 0.01; // Air resistance factor

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint n_particles = n_groups * n_particles_per_group;
    uint particles_per_thread = (n_particles + total_threads - 1) / total_threads;

    uint start_i = global_thread_id * particles_per_thread;
    uint end_i = min(start_i + particles_per_thread, n_particles);

    const vec3 gravity = vec3(0, 1, 0) * gravity_factor; // Realistic gravity

    for (uint particle_i = start_i; particle_i < end_i; ++particle_i) {
        Particle particle = particles_a[particle_i];
        ParticleGroup group = groups[particle.group_id];
        vec3 to_center = normalize(group.center - particle.position) * 100;

        float mass = particle.mass;
        particle.velocity += max(1 - elapsed / boost_duration, 0) * boost_velocity * normalize(particle.direction) * delta;
        particle.velocity += gravity * delta * dot(normalize(particle.direction), normalize(particle.velocity));

        particle.position += mass * particle.velocity * delta;
        particle.mass = max(particle.mass - mass_decay * delta, 0);
        particle.value = max(particle.value - value_decay * delta, 0);
        particles_b[particle_i] = particle;
    }
}