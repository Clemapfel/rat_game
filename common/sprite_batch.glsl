#pragma language glsl4

#ifdef VERTEX

varying vec4 vertex_color;
varying vec2 texture_coordinates;
varying flat int should_discard;

layout(std430) readonly buffer position_buffer {
    vec2 position_data[];
};

layout(std430) readonly buffer texcoord_buffer {
    vec2 texcoords_data[];
};

layout(std430) readonly buffer discard_buffer {
    int should_discard_data[];
};

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = gl_InstanceID;
    should_discard = should_discard_data[instance_id];

    int vertex_id = 0;
    if (vertex_position.x < 0 && vertex_position.y < 0) {
        vertex_id = 0;
        vertex_color = vec4(1, 0, 1, 1);
    }
    else if (vertex_position.x > 0 && vertex_position.y < 0) {
        vertex_id = 1;
        vertex_color = vec4(1, 1, 0, 1);
    }
    else if (vertex_position.x > 0 && vertex_position.y > 0) {
        vertex_id = 2;
        vertex_color = vec4(0, 1, 1, 1);
    }
    else if (vertex_position.x < 0 && vertex_position.y > 0) {
        vertex_id = 3;
        vertex_color = vec4(0, 1, 1, 1);
    }

    vertex_position.xy += position_data[instance_id];
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 vertex_color;
varying vec2 texture_coordinates;
varying flat int should_discard;

vec4 effect(vec4, Image image, vec2, vec2)
{
    if (should_discard > 0) discard;
    return Texel(image, texture_coordinates) * vertex_color;
}
#endif