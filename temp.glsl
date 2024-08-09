#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 offset_normalized = (offset / 0.1 + vec2(1)) / vec2(2);
    float value = project(0.2, 0.8, dot(offset_normalized, offset_normalized));

    //vec4 texcolor = texture2D(texture, texture_coords);
    return vec4(hsv_to_rgb(vec3(1, 0, value)) * vertex_color.xyz, 1);
}

#endif