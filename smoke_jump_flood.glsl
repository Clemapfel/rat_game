//
// step particle simulation
//

layout(rgba8) uniform readonly image2D init_texture;
layout(rg32ui) uniform uimage2D input_texture;
layout(rg32ui) uniform uimage2D output_texture;


layout(std430) buffer max_distance_buffer {
    uint max_distance[];
}; // size: 1

#define MODE_INITIALIZE 0
#define MODE_JUMP 1
uniform uint mode;
uniform int jump_distance; // The current jump distance

const float threshold = 0.5;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with texture_width,
void computemain() {
    ivec2 size = imageSize(init_texture);
    if (gl_GlobalInvocationID.x >= size.x || gl_GlobalInvocationID.y >= size.y) return;
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

    if (mode == MODE_INITIALIZE) {
        vec4 pixel = imageLoad(init_texture, position);
        if (pixel.r > threshold)
            imageStore(input_texture, position, uvec4(1, 1, 0, 0));
        else
            imageStore(input_texture, position, uvec4(0, 0, 0, 0));

        if (gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0)
            max_distance[0] = 1;
    }
    else if (mode == MODE_JUMP) {

    }
}