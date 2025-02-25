#ifdef PIXEL

const float h = 0.5;
float spiky_kernel_peak() {
    return 4 / h;
}

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 texel = texture(image, texture_coords);
    return vec4(texel.r / (spiky_kernel_peak() * 500));
}

#endif
