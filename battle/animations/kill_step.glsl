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

const float PI = 3.1415926535897932384626433832795;

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

float project(float x, float min, float max)
{
    return min + x * (max - min);
}

// ###

layout(rgba32f) uniform image2D position_texture;
layout(rgba16f) uniform image2D color_texture;
layout(r8) uniform image2D mass_texture;

uniform float delta;
uniform float elapsed;
uniform vec2 center_of_gravity;
uniform vec4 screen_aabb;
uniform vec2 dispatch_size;

const float acceleration = 1;

layout(std430) writeonly buffer n_done_counter
{
    uint n[];
};

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 position = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    // update position

    vec4 position_data = imageLoad(position_texture, position);
    vec2 current = position_data.xy;
    vec2 previous = position_data.zw;
    float mass_data = imageLoad(mass_texture, position).x; // in [0, 1]

    highp vec2 gravity = normalize(vec2(current - center_of_gravity));
    gravity = rotate(gravity, noise(position) * (PI / 4));
    gravity.y += elapsed / 100;
    gravity *= 400 * project(clamp(elapsed, 0, 1), 0.3, 1);
    float delta_squared = delta * delta;

    const float mass_factor = 10;
    const float min_mass = 0;
    const float max_mass = 1;
    float mass = project(mass_data, min_mass, max_mass) * mass_factor;

    const float min_damping = 0.98;
    const float max_damping = 1;
    float damping = 1 - gaussian(distance(position, 0.5 * dispatch_size) / max(dispatch_size.x, dispatch_size.y), 1);
    //imageStore(color_texture, position, vec4(vec3(damping), 1));

    vec2 downward_force = vec2(0, elapsed / 100); // term unaffected by mass, in case mass is 0

    damping = project(damping, min_damping, max_damping);

    vec2 next = current + (current - previous) * damping + mass * gravity * delta_squared + downward_force;

    imageStore(position_texture, position, vec4(next, current.xy));

    // check if particle left screen
    float x = screen_aabb.x;
    float y = screen_aabb.y;
    float w = screen_aabb.z;
    float h = screen_aabb.w;
    if (current.x <= x || current.y <= y || current.x >= x + w || current.y >= y + h) {
        vec4 color_data = imageLoad(color_texture, position);
        if (color_data.a >= 0) {
            atomicAdd(n[0], 1);
            imageStore(color_texture, position, vec4(-1));
        }
    }
}