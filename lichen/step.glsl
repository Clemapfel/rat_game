#pragma glsl4

layout(rgba32f) uniform image2D image_in;
layout(rgba32f) uniform image2D image_out;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 image_size = imageSize(image_in);
    ivec2 texel_coords = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    vec4 value = imageLoad(image_in, texel_coords);
    value.xyz = value.xyz + vec3(0.05);
    imageStore(image_out, texel_coords, value);
}
