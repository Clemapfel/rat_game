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
    float total_distance;
    uvec2 next_indices;
    bool has_split;
    float split_delay;
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
uniform float inertia = 0.998;
uniform float position_speed = 100;
uniform float velocity_perturbation = 0.1 * PI;

uniform float split_distance = 200;
uniform float split_cooldown = 70;

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
        if (!current.is_active || current.has_split || current.mass <= 0)
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
        current.total_distance += length(step);

        current.mass = 1 - current.total_distance / (max_split_depth * split_cooldown);

        // split
        if (current.split_depth <= max_split_depth && !current.has_split) {
            if (current.distance_since_last_split > split_cooldown) {
                float threshold = max(current.distance_since_last_split - clamp(current.split_delay, 0.3, 1) * split_cooldown, 0) / split_distance;
                if (gradient_noise(vec3(current.position * i * PI, noise_offset)) < threshold) {
                    Branch self = branches[current.next_indices.x];
                    Branch other = branches[current.next_indices.y];
                    current.has_split = true;

                    self.is_active = false;
                    other.is_active = false;

                    self.mark_active = true;
                    other.mark_active = true;

                    self.position = current.position;
                    other.position = current.position;

                    self.velocity = rotate(current.velocity, -1 * PI / 8);
                    other.velocity = rotate(current.velocity, +1 * PI / 8);

                    self.angular_velocity = current.angular_velocity;
                    other.angular_velocity = current.angular_velocity;

                    self.mass = current.mass;
                    other.mass = current.mass;

                    self.distance_since_last_split = 0;
                    other.distance_since_last_split = 0;

                    self.total_distance = current.total_distance;
                    other.total_distance = current.total_distance;

                    self.has_split = false;
                    other.has_split = false;

                    current.has_split = true;
                    current.is_active = false;

                    // keep next_indices, split_depth

                    branches[current.next_indices.x] = self;
                    branches[current.next_indices.y] = other;
                }
            }
        }

        branches[i] = current;
    }
    #endif
}