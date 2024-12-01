#ifdef PIXEL

uniform vec4 color;
uniform float weight = 0;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texel = Texel(image, texture_coords);
    return vec4(mix(color.rgb, texel.rgb, weight), texel.a);
}
#endif