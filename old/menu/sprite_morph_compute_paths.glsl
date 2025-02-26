//
// move every occupied pixel in from texture to the nearest occupied pixel in to texture
//

layout(rgba8) uniform image2D image;

struct Path {
    bool is_valid;
    vec2 a_from;
    vec2 b_from;
    vec2 a_to;
    vec2 b_to;
};

layout(std430) writeonly buffer paths_buffer {
    Path paths[];
}; // size: image_size.x * image_size.y * 4

#define PI 3.1415926535897932384626433832795

uniform vec2 image_center;
uniform float circle_radius;

void push_path(uint i, vec2 a, vec2 b) {
    const float offset = 0; //1 * PI;

    float a_angle = atan(a.y - image_center.y, a.x - image_center.x) + offset;
    vec2 a_to = image_center + vec2(cos(a_angle) * circle_radius, sin(a_angle) * circle_radius);

    float b_angle = atan(b.y - image_center.y, b.x - image_center.x) + offset;
    vec2 b_to = image_center + vec2(cos(b_angle) * circle_radius, sin(b_angle) * circle_radius);

    paths[i] = Path(
        true,
        a,
        b,
        a_to,
        b_to
    );
}

const float threshold = 0.0;

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in; // dispatch with xy = texture_size / 16
void computemain() {
    ivec2 image_size = imageSize(image);
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    if (position.x > image_size.x || position.y > image_size.y) return;

    uint path_i = (position.y * image_size.x + position.x) * 4;
    paths[path_i + 0].is_valid = false;
    paths[path_i + 1].is_valid = false;
    paths[path_i + 2].is_valid = false;
    paths[path_i + 3].is_valid = false;

    bool center = imageLoad(image, ivec2(position + vec2(0, 0))).a > threshold;
    if (center) return; // not an edge

    const vec2 top_offset = vec2(0, -1);
    const vec2 right_offset = vec2(1, 0);
    const vec2 bottom_offset = vec2(0, 1);
    const vec2 left_offset = vec2(-1, 0);

    bool top = imageLoad(image, ivec2(position + top_offset)).a > threshold;
    bool right = imageLoad(image, ivec2(position + right_offset)).a > threshold;
    bool bottom = imageLoad(image, ivec2(position + bottom_offset)).a > threshold;
    bool left = imageLoad(image, ivec2(position + left_offset)).a > threshold;

    if (!(top || right || bottom || left)) return; // not an edge

    if (top)
        push_path(path_i + 0, position.xy, position.xy + right_offset);

    if (right)
        push_path(path_i + 1, position.xy + right_offset, position.xy + right_offset + bottom_offset);

    if (bottom)
        push_path(path_i + 2, position.xy + bottom_offset, position.xy + bottom_offset + right_offset);

    if (left)
        push_path(path_i + 3, position.xy, position.xy + bottom_offset);
}