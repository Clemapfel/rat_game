//#pragma language glsl4

// src: https://py-pde.readthedocs.io/en/latest/examples_gallery/pde_brusselator_class.html

#ifndef TEXTURE_FORMAT
#define TEXTURE_FORMAT rg16f
#endif

layout(rgba16f) uniform image2D position_texture;
layout(rgba8) uniform image2D color_texture;

uniform float delta;
uniform vec2 screen_size;
uniform float floor_y;

const float position_acceleration = 2;
const float color_velocity = 0.3;
const vec2 gravity = vec2(0, 1000);

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 position = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    // update position

    vec4 position_data = imageLoad(position_texture, position);

    vec2 current = position_data.xy;
    vec2 previous = position_data.zw;

    vec2 next = current + (current - previous) + position_acceleration * (delta * delta) + gravity * delta * delta;

    next.x = clamp(next.x, 0.1 * screen_size.x, 0.9 * screen_size.x);
    next.y = clamp(next.y, 0.1 * screen_size.y, min(floor_y, 0.9 + screen_size.y));

    imageStore(position_texture, position, vec4(next, current.xy));

    // update color

    vec4 color_data = imageLoad(color_texture, position);
    color_data.a = clamp(color_data.a - color_velocity * delta, 0, 1);

    imageStore(color_texture, position, color_data);
}