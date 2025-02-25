uniform float _time;
uniform vec4 _texture_rect;   // aabb texture coordinates

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vertex_position.z += _time;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    float time = 0.5 * _time;
    float x = _texture_rect.x;
    float y = _texture_rect.y;
    float width = _texture_rect.z;
    float height = _texture_rect.w;

    vec2 texture_pos = texture_coords;
    texture_pos.x *= width / fract(time);
    return vertex_color * Texel(texture, texture_pos);
}

#endif