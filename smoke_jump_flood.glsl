//
// step particle simulation
//

layout(rgba8) uniform readonly image2D init_texture;
layout(rg32f) uniform image2D input_texture;
layout(rg32f) uniform image2D output_texture;


layout(std430) buffer max_distance_buffer {
    float max_distance[];
}; // size: 1

#define MODE_INITIALIZE 0
#define MODE_JUMP 1
uniform uint mode;
uniform int jump_distance; // The current jump distance

const float INFINITY = 3.402823466e+38 - 1;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with texture_width, texture_height
void computemain() {
    ivec2 size = imageSize(init_texture);
    if (gl_GlobalInvocationID.x >= size.x || gl_GlobalInvocationID.y >= size.y) return;
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

    if (mode == MODE_INITIALIZE) {
        vec4 pixel = imageLoad(init_texture, position);
        if (pixel.r > threshold)
            imageStore(input_texture, position, ivec4(position.xy, INFINITY, 0));
        else
            imageStore(input_texture, position, ivec4(-1, -1, 0, 0));

        if (gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0)
            max_distance[0] = 1;
    }
    else if (mode == MODE_JUMP) {
        ivec4 current = imageLoad(input_texture, position);
        ivec2 best_pos = ivec2(current.xy);
        uint best_dist = max_distance[0];

        for (int dx = -1; dx <= 1; ++dx) {
            for (int dy = -1; dy <= 1; ++dy) {
                if (dx == 0 && dy == 0) continue;

                ivec2 neighbor_pos = position + ivec2(dx, dy) * jump_distance;

                if (neighbor_pos.x < 0 || neighbor_pos.y < 0 || neighbor_pos.x >= size.x || neighbor_pos.y >= size.y) continue;

                ivec4 neighbor = imageLoad(input_texture, neighbor_pos);

                if (neighbor.x == -1) continue;

                uint dist = abs(neighbor_pos.x - position.x) + abs(neighbor_pos.y - position.y);
                if (dist < best_dist) {
                    best_dist = dist;
                    best_pos = ivec2(neighbor.xy);
                }
            }
        }

        imageStore(output_texture, position, ivec4(best_pos, current.zw));
        if (best_dist > max_distance[0])
        max_distance[0] = best_dist;
    }
}