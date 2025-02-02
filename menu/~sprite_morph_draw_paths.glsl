#pragma language glsl4

uniform sampler2D from_texture;
uniform sampler2D to_texture;

layout(std430) readonly buffer path_buffer {
    vec4 paths[];
}; // size: image_size.x * image_size.y

uniform vec2 image_size;
uniform float fraction = 0;

#ifdef VERTEX

varying vec4 color;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    vec4 path = paths[instance_id];
    vec4 from_color = texture(from_texture, path.xy / image_size);
    vec4 to_color = texture(to_texture, path.zw / image_size);

    vertex_position.xy += mix(path.xy, path.zw, clamp(fraction, 0, 1));
    color = mix(from_color, to_color, clamp(fraction, 0, 1));

    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 color;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position)
{
    return color;
}

#endif