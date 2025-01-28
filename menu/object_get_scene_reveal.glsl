#ifdef PIXEL

uniform float color;
uniform vec3 black;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position) {
    vec4 texel = texture(image, texture_coords);
    return vec4(mix(black, texel.rgb, color), texel.a);
}

#endif