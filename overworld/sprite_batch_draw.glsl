#pragma language glsl4

struct Sprite {
    vec2 top_left;
    vec2 top_right;
    vec2 bottom_right;
    vec2 bottom_left;
    vec2 texture_top_left;
    vec2 texture_top_right;
    vec2 texture_bottom_right;
    vec2 texture_bottom_left;

    bool flip_horizontally;
    bool flip_vertically;
    float angle;
};

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

layout(std430) readonly buffer SpriteBuffer {
    Sprite sprites[];
}; // size: instance count

#ifdef VERTEX

varying vec2 texture_coords;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    uint instance_id = love_InstanceID;
    Sprite sprite = sprites[instance_id];

    uint vertex_i = gl_VertexID.x;

    vec2 position_offsets[4] = vec2[4](
        sprite.top_left,
        sprite.top_right,
        sprite.bottom_right,
        sprite.bottom_left
    );
    vec2 offset = position_offsets[vertex_i];

    vec2 center = sprite.top_left + (sprite.bottom_right - sprite.top_left) / 2;
    offset -= center;
    offset = rotate(offset, sprite.angle);
    offset += center;
    vertex_position.xy += offset;

    vec2 texture_offsets[4] = vec2[4](
        sprite.texture_top_left,
        sprite.texture_top_right,
        sprite.texture_bottom_right,
        sprite.texture_bottom_left
    );
    texture_coords = texture_offsets[vertex_i];

    if (sprite.flip_horizontally)
        texture_coords.x = 1 - texture_coords.x;

    if (sprite.flip_vertically)
        texture_coords.y = 1 - texture_coords.y;

    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec2 texture_coords;

vec4 effect(vec4 color, Image image, vec2, vec2 screen_coords)
{
    return color * Texel(image, texture_coords);
}

#endif
