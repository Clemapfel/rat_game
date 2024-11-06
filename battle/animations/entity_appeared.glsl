#ifdef PIXEL

uniform float weight = 0;
uniform float alpha = 1;
uniform vec3 black;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    vec4 color = Texel(image, texture_coords);
    return vec4(mix(black, color.rgb, weight), color.a * alpha);
}
#endif