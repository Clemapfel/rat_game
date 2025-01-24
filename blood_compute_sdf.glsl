#define MODE_INITIALIZE 0        // initialize jump flood fill
#define MODE_JUMP 1              // step jump flood fill
#define MODE_COMPUTE_GRADIENT 2  // modify and compute gradient of sdf

#ifndef MODE
#error "In blood_compute_sdf.glsl: MODE is undefined, it be one of [0, 1, 2]"
#endif

#if MODE == MODE_INITIALIZE
layout(r8) uniform readonly image2D hitbox_texture;
layout(rgba32f) uniform writeonly image2D input_texture;  // xy: nearest wall pixel coords, z: distance, w: sign of distance
layout(rgba32f) uniform writeonly image2D output_texture;
#elif MODE == MODE_JUMP
layout(rgba32f) uniform readonly image2D input_texture;
layout(rgba32f) uniform writeonly image2D output_texture;
#elif MODE == MODE_COMPUTE_GRADIENT
layout(rgba32f) uniform readonly image2D input_texture;
layout(rgba32f) uniform writeonly image2D output_texture;
#endif

uniform int jump_distance; // k / 2, k / 2 / 2, ..., 1, where k = max(size(input_texture))

const float infinity = 1 / 0.f;
uniform float threshold = 0;

const ivec2 directions[8] = ivec2[](
    ivec2(0, -1),
    ivec2(1, 0),
    ivec2(0, 1),
    ivec2(-1, 0),
    ivec2(1, -1),
    ivec2(1, 1),
    ivec2(-1, 1),
    ivec2(-1, -1)
);

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // dispatch with texture_width / 8, texture_height / 8
void computemain() {
    ivec2 size = imageSize(input_texture);
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);

    if (position.x > size.x || position.y > size.y)
        return;

    #if MODE == MODE_INITIALIZE
        vec4 pixel = imageLoad(hitbox_texture, position);
        bool is_wall = false;
        if (pixel.r > threshold) {
            is_wall = true;

            uint n_others = 0;
            for (uint i = 0; i < 8; ++i) {
                vec4 other = imageLoad(hitbox_texture, position + directions[i]);
                if (other.r > threshold)
                    n_others += 1;
                else
                    break;
            }

            if (n_others >= 8) {
                vec4 inner_wall = vec4(-1, -1, infinity, -1);
                imageStore(input_texture, position, inner_wall);
            }
            else {
                vec4 wall = vec4(position.x, position.y, -1, 0);
                imageStore(input_texture, position, wall);
                imageStore(output_texture, position, wall);
            }
        } else {
            vec4 non_wall = vec4(-1, -1, infinity, 1);
            imageStore(input_texture, position, non_wall);
        }
    #elif MODE == MODE_JUMP
        vec4 self = imageLoad(input_texture, position);
        if (self.z < 0) // is wall
        return;

        vec4 best = self;
        for (int i = 0; i < 8; ++i) {
            ivec2 neighbor_position = position + directions[i] * jump_distance;

            if (neighbor_position.x < 0 || neighbor_position.x >= size.x || neighbor_position.y < 0 || neighbor_position.y >= size.y)
                continue;

            vec4 neighbor = imageLoad(input_texture, neighbor_position);
            if (neighbor.x < 0 || neighbor.y < 0) // is uninitialized
                continue;

            float dist = distance(vec2(position), vec2(neighbor.xy));
            if (dist < best.z)
            best = vec4(neighbor.xy, dist, self.w);
        }

        imageStore(output_texture, position, best);
    #endif
}