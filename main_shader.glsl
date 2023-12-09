uniform mat4 transform_projection;

#ifdef VERTEX
vec4 position(mat4 _, vec4 vertex_position)
{
    return vec4((transform_projection * vertex_position).xyz, 2);
}
#endif