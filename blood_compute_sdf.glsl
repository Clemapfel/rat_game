layout(r8) uniform readonly image2D init_texture; // r > 0 = is wall
layout(rgba32f) uniform image2D input_texture; // xy: nearest wall position, z: distance, w: unused
layout(rgba32f) uniform image2D output_texture; // "

#define MODE_INITIALIZE 0
#define MODE_JUMP 1
uniform uint mode;
uniform int jump_distance;

const float wall_threshold = 0.01;
const float infinity = 1e36;
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

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in; // dispatch with size(init_texture)
void computemain() {
    ivec2 size = imageSize(init_texture);
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

    if (mode == MODE_INITIALIZE) {
        vec4 pixel = imageLoad(init_texture, position);
        if (pixel.r > wall_threshold) {
            vec4 wall = vec4(position.x, position.y, -1, -1);
            imageStore(input_texture, position, wall);
            imageStore(output_texture, position, wall);
        }
        else
            imageStore(input_texture, position, vec4(-1, -1, infinity, 0));
    }
    else if (mode == MODE_JUMP) {
        vec4 self = imageLoad(input_texture, position);
        if (self.z < 0) // is wall pixel
            return;

        vec4 best = self;
        for (int i = 0; i < 8; ++i) {
            ivec2 neighbor_position = position + directions[i] * jump_distance;
            if (neighbor_position.x < 0 || neighbor_position.x >= size.x || neighbor_position.y < 0 || neighbor_position.y >= size.y)
                continue;

            vec4 neighbor = imageLoad(input_texture, neighbor_position);
            if (neighbor.x < 0 || neighbor.y < 0) // is unitialized
                continue;

            float dist = distance(vec2(position), vec2(neighbor_position));
            if (dist < best.z)
                best = vec4(neighbor.xy, dist, 0);
        }

        imageStore(output_texture, position, best);
    }
}
