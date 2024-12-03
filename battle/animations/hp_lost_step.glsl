struct Particle {
    vec2 current;
    float angle;
    float velocity;
    float damping;
    float hue;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
};

uniform float delta;
uniform float damping_speed;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    uint particle_i = gl_GlobalInvocationID.x;
    Particle particle = particles[particle_i];

    vec2 direction = vec2(cos(particle.angle), sin(particle.angle));
    particle.current += direction * delta * particle.velocity * (1 - particle.damping);
    particle.damping = clamp(particle.damping + delta / damping_speed, 0, 1);

    particles[particle_i] = particle;
}