//
// generate segment pairs that contour binary texture
//

layout(rgba8) uniform image2D input_texture;
layout(std430) buffer segments_buffer {
    vec4 segments[];
}; // size: image_size.x * image_size.y * 4

const float threshold = 0.1;

layout(local_size_x = 16, local_size_y = 16) in; // dispatch with xy = texture_size / 16
void computemain() {
    ivec2 image_size = imageSize(input_texture);

    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    if (position.x > image_size.x || position.y > image_size.y) return;

    uint segment_i = (position.y * image_size.x + position.x) * 4;

    const vec4 default_segment = vec4(-1, -1, -1, -1);
    segments[segment_i + 0] = default_segment;
    segments[segment_i + 1] = default_segment;
    segments[segment_i + 2] = default_segment;
    segments[segment_i + 3] = default_segment;

    bool center = imageLoad(input_texture, ivec2(position + vec2(0, 0))).a > threshold;
    if (center) return; // not an edge

    const vec2 top_offset = vec2(0, -1);
    const vec2 right_offset = vec2(1, 0);
    const vec2 bottom_offset = vec2(0, 1);
    const vec2 left_offset = vec2(-1, 0);

    bool top = imageLoad(input_texture, ivec2(position + top_offset)).a > threshold;
    bool right = imageLoad(input_texture, ivec2(position + right_offset)).a > threshold;
    bool bottom = imageLoad(input_texture, ivec2(position + bottom_offset)).a > threshold;
    bool left = imageLoad(input_texture, ivec2(position + left_offset)).a > threshold;

    if (!(top || right || bottom || left)) return; // not an edge

    if (top)
        segments[segment_i + 0] = vec4(position.xy, position.xy + right_offset);

    if (right)
        segments[segment_i + 1] = vec4(position.xy + right_offset, position.xy + right_offset + bottom_offset);

    if (bottom)
        segments[segment_i + 2] = vec4(position.xy + bottom_offset, position.xy + bottom_offset + right_offset);

    if (left)
        segments[segment_i + 3] = vec4(position.xy, position.xy + bottom_offset);
}