
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
uniform float elapsed;

layout(rgba32f) uniform image2D sdf_texture;

const mat3 sobel_x = mat3(
    -1.0, 0.0, 1.0,
    -2.0, 0.0, 2.0,
    -1.0, 0.0, 1.0
);

const mat3 sobel_y = mat3(
    -1.0, -2.0, -1.0,
    0.0,  0.0,  0.0,
    1.0,  2.0,  1.0
);

const ivec2 directions[8] = ivec2[](
    ivec2(0, -1),
    ivec2(1, 0),
    ivec2(0, 1),
    ivec2(-1, 0),
    ivec2(1, -1),
    ivec2(1, 1),
    ivec2(-1, 1),
    ivec2(-1, -1)
);

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
    dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    const float K1 = 0.366025404;  // (sqrt(3)-1)/2
    const float K2 = 0.211324865;  // (3-sqrt(3))/6

    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = step(a.yx, a.xy);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;

    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)),
    dot(b, hash(i + o)),
    dot(c, hash(i + 1.0)));

    return dot(n, vec3(70.0));
}

float get_signed_distance(ivec2 position) {
    vec4 data = imageLoad(sdf_texture, position);
    return data.z * data.w;
}

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

        ivec2 position = ivec2(particle.position);
        float sdf_00 = get_signed_distance(position + ivec2(-1, -1));
        float sdf_01 = get_signed_distance(position + ivec2( 0, -1));
        float sdf_02 = get_signed_distance(position + ivec2( 1, -1));
        float sdf_10 = get_signed_distance(position + ivec2(-1,  0));
        float sdf_12 = get_signed_distance(position + ivec2( 1,  0));
        float sdf_20 = get_signed_distance(position + ivec2(-1,  1));
        float sdf_21 = get_signed_distance(position + ivec2( 0,  1));
        float sdf_22 = get_signed_distance(position + ivec2( 1,  1));

        float sobel_x = (sdf_02 + 2.0 * sdf_12 + sdf_22) - (sdf_00 + 2.0 * sdf_10 + sdf_20);
        float sobel_y = (sdf_20 + 2.0 * sdf_21 + sdf_22) - (sdf_00 + 2.0 * sdf_01 + sdf_02);

        vec2 sdf_gradient = vec2(sobel_x, sobel_y);
        float distance = get_signed_distance(position) / max(bounds.z, bounds.w) / 2;
        particle.velocity = -1 * sdf_gradient * distance * (10 * elapsed);

        // apply spin
        float spin_force = 1; // Adjust this value to control rotation speed
        float angle = elapsed + particle_i * 3;
        vec2 spin_velocity = vec2(
            cos(angle),
            sin(angle)
        ) * spin_force;

        particle.velocity += spin_velocity;

        particle.position += particle.velocity *  delta;

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