
uniform Image sdf_texture;

#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float signed_distance = Texel(sdf_texture, texture_coords).x;
    const float border = 0.001;
    float value = smoothstep(-border, +border, signed_distance);
    return vec4(vec3(1 - value), 1);
}

#endif
