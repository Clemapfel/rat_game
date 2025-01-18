#ifdef PIXEL

vec4 effect(vec4, Image density, vec2 texture_coords, vec2) {
    vec4 data = texture(density, texture_coords);
    return vec4(vec3(data.r), 1);
}

#endif