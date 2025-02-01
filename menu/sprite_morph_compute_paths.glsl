//
// move every occupied pixel in from texture to the nearest occupied pixel in to texture
//

layout(rgba8) uniform image2D from_texture;
layout(rgba8) uniform image2D to_texture;

layout(std430) writeonly buffer path_buffer {
    vec4 paths[];
}; // size: image_size.x * image_size.y

const float threshold = 0.0;

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in; // dispatch with xy = texture_size / 16
void computemain() {
    ivec2 image_size = imageSize(from_texture);

    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    if (position.x > image_size.x || position.y > image_size.y) return;

    uint path_i = (position.y * image_size.x + position.x);
    if (imageLoad(to_texture, position).a > threshold) {      // pixel maps to same position
        paths[path_i] = vec4(position.xy, position.xy);
        return;
    }
    
    // find nearest occupied pixel in to_texture by searching in spiral pattern
    
    ivec2 current_position = position;
    ivec2 direction = ivec2(1, 0);
    int steps = 1; // Number of steps in the current direction
    int step_count = 0; // Steps taken in the current direction
    int n_direction_changes = 0; // Number of direction changes

    for (int i = 0; i < image_size.x * image_size.y; ++i) {
        if (current_position.x >= 0 && current_position.x < image_size.x && current_position.y >= 0 && current_position.y < image_size.y) {
            if (imageLoad(to_texture, current_position).a > threshold) {
                paths[path_i] = vec4(position.xy, current_position.xy);
                return;
            }
        }

        current_position += direction;
        step_count++;

        if (step_count == steps) {
            step_count = 0;
            n_direction_changes++;

            if (direction.x == 1) {
                direction = ivec2(0, 1);
            } else if (direction.y == 1) {
                direction = ivec2(-1, 0);
            } else if (direction.x == -1) {
                direction = ivec2(0, -1);
            } else if (direction.y == -1) {
                direction = ivec2(1, 0);
            }

            if (n_direction_changes % 2 == 0) {
                steps++;
            }
        }
    }

    paths[path_i] = vec4(position.xy, position.xy); // no match found
}