#ifdef PIXEL

uniform float weight = 0;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texel = Texel(image, texture_coords);
    vec3 inverse = 1 - texel.rgb;
    inverse.xyz = vec3(max(max(inverse.x, inverse.y), max(inverse.y, inverse.z)));
    return vec4(mix(texel.rgb, inverse, weight), texel.a) * vertex_color;
}
#endif