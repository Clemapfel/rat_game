#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image _, vec2 texture_position, vec2 vertex_position) {
    float value = 1 - (distance(vertex_position / love_ScreenSize.xy, vec2(0.5)) * 2);
    return vec4(value);
}

#endif