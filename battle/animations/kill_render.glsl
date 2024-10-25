uniform sampler2D position_texture;
uniform sampler2D color_texture;

#ifdef VERTEX

uniform vec2 snapshot_size;
varying vec4 vertex_color;

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = love_InstanceID;

    vec2 texture_coordinates = vec2(instance_id / snapshot_size.x, mod(instance_id, snapshot_size.x));
    vec4 position_data = texelFetch(position_texture, ivec2(texture_coordinates), 0);
    vertex_position.xy += position_data.xy;

    vec4 color_data = texelFetch(color_texture, ivec2(texture_coordinates), 0);
    vertex_color = color_data;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 vertex_color;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 screen_coords)
{
    const float boundary = 0.1;
    bool within_boundary = all(greaterThanEqual(texture_coords, vec2(boundary))) && all(lessThanEqual(texture_coords, vec2(1.0 - boundary)));
    return vertex_color;
    return within_boundary ? vertex_color : vec4(vec3(1), 1);
}
#endif