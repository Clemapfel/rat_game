//#pragma language glsl4


layout(rgba16f) uniform image2D texture_in;
layout(rgba16f) uniform image2D texture_out;
//layout(rgb16) uniform image2D vector_field;


layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain()
{
    ivec2 image_size = imageSize(texture_in);
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    int width = image_size.x;
    int height = image_size.y;

    vec4 current = imageLoad(texture_in, ivec2(x, y));
    imageStore(texture_out, ivec2(x, y), vec4(current.xyz + vec3(0.02), 0));
}