#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 value = Texel(image, texture_coords);
    return vec4(vec3(length(value.xy) / 10), 1);
}

#endif
