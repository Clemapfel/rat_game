#pragma language glsl4

#ifdef VERTEX

varying vec2 texture_coordinates;
varying vec4 vertex_color;
varying flat int should_discard;

#define BUFFER_LAYOUT layout(std430) readonly

BUFFER_LAYOUT buffer offset_buffer {
    vec2 offsets[];
};

struct Position {
    vec2 _01;
    vec2 _02;
    vec2 _03;
    vec2 _04;
};

BUFFER_LAYOUT buffer position_buffer {
    Position positions[];
};

BUFFER_LAYOUT buffer texcoord_buffer {
    mat4x2 texcoords[];
};

BUFFER_LAYOUT buffer discard_buffer {
    int discards[];
};

uniform int n_vertices_per_instance = 4;

vec4 position(mat4 transform, vec4 vertex_position)
{
    int instance_id = gl_InstanceID;
    int vertex_id = gl_VertexID % n_vertices_per_instance;

    vec2 position;
    if (vertex_id == 0)
        position = positions[instance_id]._01;

    if (vertex_id == 1)
        position = positions[instance_id]._02;

    if (vertex_id == 2)
        position = positions[instance_id]._03;

    if (vertex_id == 3)
        position = positions[instance_id]._04;

    vertex_position.xy += position.xy;

    /*
    vec2 texture_coordinates = vec2(
        texcoords[instance_id][vertex_id][0],
        texcoords[instance_id][vertex_id][1]
    );
    */

    should_discard = discards[instance_id];

    vertex_position.xy += offsets[instance_id];
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec2 texture_coordinates;
varying vec4 vertex_color;
varying flat int should_discard;

vec4 effect(vec4, Image image, vec2, vec2)
{
    if (should_discard > 0) discard;
    return Texel(image, texture_coordinates);
}
#endif