#ifdef PIXEL

vec4 effect(vec4 vertex_color, Image _, vec2 texture_position, vec2 vertex_position) {
    const float eps = 0.13;
    float dist = distance(vertex_position / love_ScreenSize.xy, vec2(0.5));
    float value = smoothstep(0.5, 0.5 + eps, 1 - dist);
    return vec4(value);
}

#endif