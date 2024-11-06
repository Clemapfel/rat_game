#pragma language glsl4

#ifdef VERTEX

varying vec2 texture_coordinates;
varying flat int should_discard;

#define BUFFER_LAYOUT layout(std430) readonly

BUFFER_LAYOUT buffer offset_buffer {
    vec2 offsets[];
};

BUFFER_LAYOUT buffer position_buffer {
    mat2x4 positions[];
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
    int vertex_index = instance_id % n_vertices_per_instance;

    vertex_position.xy = vec2(
        positions[instance_id][vertex_index][0],
        positions[instance_id][vertex_index][1]
    );

    vec2 texture_coordinates = vec2(
        texcoords[instance_id][vertex_index][0],
        texcoords[instance_id][vertex_index][1]
    );

    should_discard = discards[instance_id];

    vertex_position.xy += offsets[instance_id];
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec2 texture_coordinates;
varying flat int should_discard;

vec4 effect(vec4, Image image, vec2, vec2)
{
    //if (should_discard > 0) discard;
    return vec4(1); //Texel(image, texture_coordinates);
}
#endif