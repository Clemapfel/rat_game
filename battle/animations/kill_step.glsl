layout(rgba32f) uniform image2D position_texture;
layout(rgba8) uniform image2D color_texture;
layout(r8) uniform image2D mass_texture;

uniform vec2 screen_size;
uniform float delta;

const float acceleration = 1;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 position = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    // update position

    vec4 position_data = imageLoad(position_texture, position);
    vec2 current = position_data.xy;
    vec2 previous = position_data.zw;
    float mass_data = imageLoad(mass_texture, position).x;

    vec2 gravity = vec2(0);

    float delta_squared = delta * delta;
    float mass = clamp(mass_data, 0.99, 1) * 100;
    vec2 next = current + (current - previous) * acceleration + mass * gravity * delta_squared;

    imageStore(position_texture, position, vec4(next, current.xy));

    // TODO:
    imageStore(color_texture, position, vec4(vec3(mass_data), 1));
}