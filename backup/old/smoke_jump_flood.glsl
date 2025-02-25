layout(rgba8) uniform readonly image2D init_texture;
layout(rgba32f) uniform image2D input_texture;
layout(rgba32f) uniform image2D output_texture;

layout(std430) buffer max_distance_buffer {
    uint max_distance[];
}; // size: 1

#define MODE_INITIALIZE 0
#define MODE_JUMP 1
uniform uint mode;
uniform int jump_distance; // The current jump distance

const float INFINITY = 3.402823466e+38 - 1;
const float threshold = 0.2;

const ivec2 directions[8] = ivec2[](
    ivec2(-1, -1),
    ivec2( 0, -1),
    ivec2( 1, -1),
    ivec2(-1,  0),
    ivec2( 1,  0),
    ivec2(-1,  1),
    ivec2( 0,  1),
    ivec2( 1,  1)
);

bool is_wall(vec4 data) {
    return data.z < 0;
}

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with texture_width, texture_height
void computemain() {
    ivec2 size = imageSize(init_texture);
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

    if (mode == MODE_INITIALIZE) {
        vec4 pixel = imageLoad(init_texture, position);
        if (pixel.a > threshold)
            imageStore(input_texture, position, vec4(position.x, position.y, -1, -1));
        else
            imageStore(input_texture, position, vec4(-1, -1, INFINITY, 0));

        if (gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0)
            max_distance[0] = 0;
    }
    else if (mode == MODE_JUMP) {
        vec4 self = imageLoad(input_texture, position);
        if (is_wall(self)) {
            imageStore(output_texture, position, self);
            return;
        }

        vec4 best = self;
        for (int i = 0; i < 8; ++i) {
            ivec2 neighbor_position = position + directions[i] * jump_distance;
            if (neighbor_position.x < 0 || neighbor_position.x >= size.x || neighbor_position.y < 0 || neighbor_position.y >= size.y)
                continue;

            vec4 neighbor = imageLoad(input_texture, neighbor_position);
            if (neighbor.x < 0 || neighbor.y < 0)
                continue;

            float dist = distance(vec2(position), vec2(neighbor.xy));
            if (dist < best.z)
                best = vec4(neighbor.xy, dist, 0);
        }

        imageStore(output_texture, position, best);

        //if (best.z < max_distance[0])
            //atomicMax(max_distance[0], uint(best.z));
    }
}