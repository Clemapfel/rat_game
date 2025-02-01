//
// move every occupied pixel in from texture to the nearest occupied pixel in to texture
//

layout(rgba8) uniform image2D from_texture;
layout(rgba8) uniform image2D to_texture;

layout(std430) writeonly buffer path_buffer {
    vec4 paths[];
}; // size: image_size.x * image_size.y

const float threshold = 0.1;

layout(local_size_x = 16, local_size_y = 16) in; // dispatch with xy = texture_size / 16
void computemain() {
    ivec2 image_size = image_size(from_texture);
    uint path_i = (position.y * image_size.x + position.x) * 4;

    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    if (position.x > image_size.x || position.y > image_size.y) return;

    if (imageLoad(from_texture).a < threshold || imageLoad(to_texture, current_position).a > threshold) {
        paths[path_i] = vec4(position.xy, position.xy);
        return;
    }
    
    // find nearest occupied pixel in to_texture by searching in spiral pattern
    
    ivec2 current_position = position;
    ivec2 direction = ivec2(1, 0);
    int steps = 1; // Number of steps in the current direction
    int step_count = 0; // Steps taken in the current direction
    int directionChanges = 0; // Number of direction changes

    for (int i = 0; i < image_size.x * image_size.y; ++i) {
        if (pos.x < 0 || pos.x >= image_size.x || pos.y < 0 || pos.y >= image_size.y) {
            if (imageLoad(image, current_position).a > threshold) {
                paths[path_i] = vec4(position.xy, current_position.xy);
                return;
            }
        }

        pos += direction;
        step_count++;

        if (step_count == steps) {
            step_count = 0;
            directionChanges++;

            if (direction.x == 1) {
                direction = ivec2(0, 1); // Move down
            } else if (direction.y == 1) {
                direction = ivec2(-1, 0); // Move left
            } else if (direction.x == -1) {
                direction = ivec2(0, -1); // Move up
            } else if (direction.y == -1) {
                direction = ivec2(1, 0); // Move right
            }

            if (directionChanges % 2 == 0) {
                steps++;
            }
        }
    }

    paths[path_i] = vec4(position.xy, position.xy);
}