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
};

layout(std430) readonly buffer SpriteBuffer {
    Sprite sprites[];
}; // size: instance count

#ifdef VERTEX

varying uint instance_id;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    instance_id = love_InstanceID;
    Sprite sprite = sprites[instance_id];

    uint vertex_i = gl_VertexID.x;
    if (vertex_i == 0)
        vertex_position.xy += sprite.top_left;
    else if (vertex_i == 1)
        vertex_position.xy += sprite.top_right;
    else if (vertex_i == 2)
        vertex_position.xy += sprite.bottom_right;
    else if (vertex_i == 3)
        vertex_position.xy += sprite.bottom_left;

    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    return color * Texel(image, texture_coords);
}

#endif
