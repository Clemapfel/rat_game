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

layout(std430) buffer writeonly particle_buffer {
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

const uint MODE_ASCEND = 0;
const uint MODE_EXPLODE = 1;
const float perturbation = 0.01;

// @return [-1, 1]
float noise(int n) {
    n = (n << 13) ^ n;
    return (1.0 - float((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0);
}

#define PI 3.141592653589793

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint n_particles = n_groups * n_particles_per_group;
    uint particles_per_thread = (n_particles + total_threads - 1) / total_threads;

    uint start_i = global_thread_id * particles_per_thread;
    uint end_i = min(start_i + particles_per_thread, n_particles);

    for (uint particle_i = start_i; particle_i < end_i; ++particle_i) {
        uint group_i = uint(floor(particle_i / float(n_particles_per_group)));
        ParticleGroup group = groups[group_i];

        float index = (particle_i - group_i * n_particles_per_group) - 1.0 + 0.5;
        float phi = acos(1.0 - 2.0 * index / float(n_particles_per_group));
        float theta = PI * (1.0 + sqrt(5.0)) * index;
        phi += noise(int(particle_i)) * perturbation * PI;
        theta += noise(int(particle_i + 1)) * perturbation * PI;

        float vx = cos(theta) * sin(phi);
        float vy = sin(theta) * sin(phi);
        float vz = cos(phi);

        particles[particle_i] = Particle(
            group.start, // position
            vec3(vx, vy, vz), // direction
            vec3(0), // velocity
            (noise(int(particle_i)) + 1) / 2.0, // hue
            1, // value
            1, // mass
            group_i,
            MODE_ASCEND
        );
    }
}