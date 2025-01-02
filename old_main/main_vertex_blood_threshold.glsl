uniform float threshold;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 texel = texture(image, texture_coords);
    if (texel.r > threshold)
        return vec4(1, 0, 1, 1);
    else
        return vec4(0);
}