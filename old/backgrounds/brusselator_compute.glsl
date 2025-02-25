//#pragma language glsl4

// src: https://py-pde.readthedocs.io/en/latest/examples_gallery/pde_brusselator_class.html

#ifndef TEXTURE_FORMAT
#define TEXTURE_FORMAT rg16f
#endif

layout(TEXTURE_FORMAT) uniform image2D texture_in;
layout(TEXTURE_FORMAT) uniform image2D texture_out;

uniform vec2 diffusivity;
uniform float a;
uniform float b;
uniform float delta;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 image_size = imageSize(texture_in);
    ivec2 position = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);
    int width = image_size.x;
    int height = image_size.y;

    // compute laplacian through convolution with kernel
    //   1   2   1
    //   2 -12   2
    //   1   2   1
    vec2 laplacian = vec2(0.0);
    laplacian += imageLoad(texture_in, position).xy * -12;
    laplacian += imageLoad(texture_in, (position + ivec2(-1,  0) + image_size) % image_size).xy * 2;
    laplacian += imageLoad(texture_in, (position + ivec2( 0, -1) + image_size) % image_size).xy * 2;
    laplacian += imageLoad(texture_in, (position + ivec2( 0,  1) + image_size) % image_size).xy * 2;
    laplacian += imageLoad(texture_in, (position + ivec2( 1,  0) + image_size) % image_size).xy * 2;
    laplacian += imageLoad(texture_in, (position + ivec2(-1,  1) + image_size) % image_size).xy * 1;
    laplacian += imageLoad(texture_in, (position + ivec2( 1, -1) + image_size) % image_size).xy * 1;
    laplacian += imageLoad(texture_in, (position + ivec2( 1,  1) + image_size) % image_size).xy * 1;
    laplacian += imageLoad(texture_in, (position + ivec2( 1,  1) + image_size) % image_size).xy * 1;

    vec2 uv = imageLoad(texture_in, position).xy;
    float u = uv.x;
    float v = uv.y;
    float u_squared = u * u;
    vec2 rhs = vec2(0);
    rhs.x = diffusivity.x * laplacian.x + a - (1.0 + b) * u + v * u_squared;
    rhs.y = diffusivity.y * laplacian.y + b * u - v * u_squared;

    //rhs.x = diffusivity.x * laplacian.x + v * u_squared + (1 + b) * u + a;
    //rhs.y = diffusivity.y * laplacian.y - v * u_squared + b * u;

    imageStore(texture_out, position, vec4(uv + rhs * delta, 0, 0));
}