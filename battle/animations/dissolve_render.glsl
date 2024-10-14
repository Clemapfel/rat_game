//#pragma language glsl3

uniform sampler2D position_texture;
uniform sampler2D color_texture;

#ifdef VERTEX

varying vec4 vertex_color;

vec2 instance_id_to_texture_coordinates(int i) {
    return vec2(i, 0);
}

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = love_InstanceID;

    ivec2 texture_coordinates = ivec2(instance_id, 0);
    vec4 position_data = texelFetch(position_texture, texture_coordinates, 0);
    vertex_position.xy += position_data.xy;

    vec4 color_data = texelFetch(color_texture, texture_coordinates, 0);
    vertex_color = color_data;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 vertex_color;

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    return vertex_color;
}
#endif