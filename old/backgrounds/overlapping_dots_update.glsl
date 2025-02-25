/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

float random_1d(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

/// @brief gradient noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/gnoise.glsl
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

// ---

struct InstanceData {
    vec2 center;
    uint quantized_radius; // as uint so it can be radix sorted
    float rotation;
    float hue;
};

layout(std430) buffer instance_data_buffer {
    InstanceData instance_data[]; // size: n_instances
};

uniform float elapsed = 0;
uniform uint n_instances;
uniform float max_radius;
uniform uint radius_denominator;
uniform vec2 screen_size;

layout(local_size_x = 64) in;
void computemain() {
    uint instance_i = gl_GlobalInvocationID.x;
    if (instance_i > n_instances) return;
    InstanceData instance = instance_data[instance_i];

    float time = elapsed / 4;

    const float scale = 4;
    vec2 position = (instance.center / screen_size) * scale;

    float new_radius = gradient_noise(vec3(position, time)); // in [0, 1]
    instance.quantized_radius = uint(round(new_radius * float(radius_denominator)));

    instance_data[instance_i] = instance;
}