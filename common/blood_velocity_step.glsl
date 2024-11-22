vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float noise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
    0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0

    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// ###

#define PI 3.1415926535897932384626433832795

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float sine_wave(float x, float frequency) {
    return (sin(2.0 * PI * x * frequency - PI / 2.0) + 1.0) * 0.5;
}

uniform int thread_group_stride = 1;
int get_particle_index(int x, int y) {
    return y * thread_group_stride + x;
}

struct Particle {
    vec2 current_position;
    vec2 previous_position;
    float radius;
    float angle;
    float color;
};

layout(std430) buffer particle_buffer {
    Particle particles[];
};

uniform float delta;
uniform float elapsed;
uniform vec2 screen_size;
uniform int n_particles;
uniform vec2 center_of_gravity;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    const float position_speed = 100;
    const float color_min = 0.1;
    const float color_max = 1;
    const float color_speed = 0.2;

    const float radius_speed = 2;
    const float radius_min = 0.4;
    const float radius_max = 2;

    const float angle_speed = 0.1 * 2 * PI;

    int particle_i = get_particle_index(int(gl_GlobalInvocationID.x), int(gl_GlobalInvocationID.y));
    Particle particle = particles[particle_i];

    // update position
    vec2 previous = particle.previous_position;
    vec2 current = particle.current_position;

    vec2 gravity = -1 * normalize(vec2(current - center_of_gravity));

    vec2 next = current;
    next += (current - previous) + position_speed * gravity * delta * delta;

    particles[particle_i].previous_position = current;
    particles[particle_i].current_position = next;

    // update color
    float value = particle.color;
    value = project(noise(vec2(particle_i, particle_i) + elapsed * color_speed), color_min, color_max);

    particles[particle_i].color = value;

    // update radius
    float radius = particle.radius;
    radius = project(sine_wave(particle_i + elapsed / 10, radius_speed), radius_min, radius_max);

    particles[particle_i].radius = radius;

    // update angle
    float angle = particles[particle_i].angle;
    particles[particle_i].angle = mod(angle + delta * angle_speed, 2 * PI);
}