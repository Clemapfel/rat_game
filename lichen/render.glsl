#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 value = Texel(image, texture_coords);
    float state = value.x;
    vec2 vector = value.yz;
    float age = value.w;
    return vec4(vec3(state), 1);
}

#endif
