uniform layout(rgba32f) image2D cell_texture_in;
uniform layout(rgba32f) image2D cell_texture_out;
uniform layout (r32i) coherent iimage2D cell_offset_texture;

uniform float delta = 1.0 / 60.0;

const vec2 directions[9] = vec2[9](
    vec2( 0,  0),  // center

    vec2( 0,  1),  // top
    vec2( 1,  0),  // right
    vec2( 0, -1),  // bottom
    vec2(-1,  0),  // left

    vec2( 1,  1),  // top-right
    vec2( 1, -1),  // bottom-right
    vec2(-1, -1),  // bottom-left
    vec2(-1,  1)   // top-left
);

const float directional_weights[9] = float[9](
    4.0 / 9.0,   // center
    1.0 / 9.0,   // top
    1.0 / 9.0,   // right
    1.0 / 9.0,   // bottom
    1.0 / 9.0,   // left

    1.0 / 36.0,  // top-right
    1.0 / 36.0,  // bottom-right
    1.0 / 36.0,  // bottom-left
    1.0 / 36.0   // top-left
);

#define INT_NORMALIZATION 32768 // quantize float offsets in int texture
#define MODE_APPLY_OFFSET 1
#define MODE_UPDATE 2
uniform int mode = MODE_UPDATE;

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture_in);
    vec4 self = imageLoad(cell_texture_in, position);

    if (mode == MODE_APPLY_OFFSET) {
        int offset = imageLoad(cell_offset_texture, position).x;
        imageStore(cell_texture_in, position, vec4(self.x + offset / float(INT_NORMALIZATION), self.yzw));
        imageStore(cell_offset_texture, position, ivec4(0));
    }
    else if (mode == MODE_UPDATE) {
        float viscosity = 0.05; // % outflow per second
        float gradients[9];
        float total_gradient = 0.0;
        for (int i = 1; i < 9; ++i) {
            ivec2 neighbor_position = ivec2(position + directions[i]);
            if (neighbor_position.x < 0 || neighbor_position.x >= size.x || neighbor_position.y < 0 || neighbor_position.y >= size.y) {
                gradients[i] = 0.0;
                continue;
            }

            vec4 neighbor = imageLoad(cell_texture_in, neighbor_position);
            float gradient = max(neighbor.x - self.x, 0) * (1 - dot(normalize(self.yz), normalize(neighbor.yz)));
            gradients[i] = gradient;
            total_gradient += gradient;
        }

        float total_offset = 0;
        for (int i = 1; i < 9; ++i) {
            ivec2 neighbor_position = ivec2(position + directions[i]);
            float fraction = (gradients[i] / total_gradient) * self.x * viscosity * delta;
            imageAtomicAdd(cell_offset_texture, neighbor_position, int(fraction * INT_NORMALIZATION));
            total_offset += fraction;
        }

        imageAtomicAdd(cell_offset_texture, position, -1 * int(total_offset * INT_NORMALIZATION));
    }
}