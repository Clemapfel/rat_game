
uniform Image sdf_texture;

#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 value = Texel(sdf_texture, texture_coords);
    float signed_distance = value.a;
    vec3 color = value.rgb;
    const float border = 0.001;
    float final = smoothstep(-border, +border, signed_distance);
    return vec4(vec3(1 - final) * color, 1);
}

#endif
