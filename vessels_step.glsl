uniform float noise_offset;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i + vec2(noise_offset, noise_offset));
    float b = hash(i + vec2(1.0, 0.0) + vec2(noise_offset, noise_offset));
    float c = hash(i + vec2(0.0, 1.0) + vec2(noise_offset, noise_offset));
    float d = hash(i + vec2(1.0, 1.0) + vec2(noise_offset, noise_offset));

    vec2 u = f * f * (3.0 - 2.0 * f);
    float result = mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
    return result * 2.0 - 1.0;
}

vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

float gradient_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    return mix( mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

vec2 rotate(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * v;
}

struct Branch {
    bool is_active;
    bool mark_active;
    vec2 position;
    vec2 velocity;
    float angular_velocity;
    float mass;
    float distance_since_last_split;
    uint next_index;
    bool has_split;
    uint split_depth;
};

uniform uint n_branches;
uniform uint max_split_depth;
layout(rgba32f) uniform readonly image2D sdf_texture; // xy: gradient, z: distance, w: sign
uniform float hitbox_strength = 0.0;

layout(std430) buffer BranchBuffer {
    Branch branches[];
}; // size: n_branches

#define MODE_STEP 0
#define MODE_MARK_ACTIVE 1

#ifndef MODE
#error "In vessels_step.glsl: MODE is undefined, it should be 0 or 1"
#endif

#define PI 3.1415926535897932384626433832795

uniform float delta = 1 / 120;
uniform float inertia = 0.985;
uniform float position_speed = 100;
uniform float mass_decay_speed = 0.1;
uniform float velocity_perturbation = 0.0 * PI;

uniform float split_distance = 200;
uniform float split_cooldown = 20;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    uint global_thread_id = gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x + gl_GlobalInvocationID.x;
    uint total_threads = gl_NumWorkGroups.x * gl_NumWorkGroups.y * gl_WorkGroupSize.x * gl_WorkGroupSize.y;
    uint branches_per_thread = (n_branches + total_threads - 1) / total_threads;

    uint start_i = global_thread_id * branches_per_thread;
    uint end_i = min(start_i + branches_per_thread, n_branches);

    #if MODE == MODE_MARK_ACTIVE

    // thread-safe atomic update of active
    for (uint i = start_i; i < end_i; ++i) {
        Branch branch = branches[i];
        if (branch.is_active == false && branch.mark_active == true) {
            branch.is_active = true;
            branches[i] = branch;
        }
    }

    #elif MODE == MODE_STEP

    // step simulation
    for (uint i = start_i; i < end_i; ++i) {
        Branch current = branches[i];
        if (!current.is_active || current.mass <= 0)
            continue;

        float offset = noise(current.position * i) * velocity_perturbation;

        current.angular_velocity = current.angular_velocity * inertia + offset * (1 - inertia);
        current.velocity = rotate(current.velocity, current.angular_velocity);

        // collision
        current.velocity += -1 * imageLoad(sdf_texture, ivec2(round(current.position))).xy * hitbox_strength;

        const float max_velocity = 3;
        if (length(current.velocity) > max_velocity)
            current.velocity = normalize(current.velocity) * max_velocity;

        vec2 step = delta * position_speed * current.velocity;
        current.position += step;
        current.distance_since_last_split += length(step);

        current.mass = current.mass - delta * mass_decay_speed;

        // split
        if (current.split_depth <= max_split_depth && !current.has_split) {
            if (current.distance_since_last_split > split_cooldown) {
                float threshold = max(current.distance_since_last_split - current.mass * split_cooldown, 0) / split_distance;
                if (gradient_noise(vec3(current.position * i * PI, noise_offset)) < threshold) {
                    Branch next = branches[current.next_index];

                    vec2 velocity = current.velocity;
                    current.distance_since_last_split = 0;
                    current.velocity = rotate(velocity, -1 * PI / 8);
                    current.has_split = true;

                    next.is_active = false;
                    next.mark_active = true;
                    next.position = current.position;
                    next.velocity = rotate(velocity, +1 * PI / 8);
                    next.angular_velocity = 0;
                    next.mass = current.mass;
                    next.distance_since_last_split = 0;
                    next.next_index = next.next_index;
                    next.has_split = false;
                    next.split_depth = next.split_depth;

                    branches[current.next_index] = next;
                }
            }
        }

        branches[i] = current;
    }
    #endif
}