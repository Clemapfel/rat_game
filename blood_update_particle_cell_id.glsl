//
// for all particles, write cell id based on current particle position
//

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform uint n_particles;
uniform uint n_rows;
uniform uint n_columns;
uniform uint cell_width;
uniform uint cell_height;

#ifndef LOCAL_SIZE_X
    #define LOCAL_SIZE_X 32
#endif

#ifndef LOCAL_SIZE_Y
    #define LOCAL_SIZE_Y 32
#endif

uint position_to_cell_linear_index(vec2 position) {
    uint cell_x = uint(floor(position.x / cell_width));
    uint cell_y = uint(floor(position.y / cell_height));
    return cell_y * n_rows + cell_x;
}

layout (local_size_x = LOCAL_SIZE_X, local_size_y = LOCAL_SIZE_Y, local_size_z = 1) in; // dispatch with sqrt(n_particles) / LOCAL_SIZE_X, sqrt(n_particles) / LOCAL_SIZE_Y
void computemain()
{
    uint thread_i = gl_LocalInvocationID.y * gl_WorkGroupSize.x + gl_LocalInvocationID.x;
    uint n_particles_per_thread = uint(ceil(n_particles / float(gl_WorkGroupSize.x * gl_WorkGroupSize.y)));
    uint particle_start_i = thread_i * n_particles_per_thread;
    uint particle_end_i = min(particle_start_i + n_particles_per_thread, n_particles);

    for (uint particle_i = particle_start_i; particle_i < particle_end_i; particle_i++) {
        Particle particle = particles[particle_i];
        particle.cell_id = position_to_cell_linear_index(particle.position);
        particles[particle_i] = particle;
    }
}