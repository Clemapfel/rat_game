#ifdef PIXEL

vec4 effect(vec4 color, Image sdf_texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture(sdf_texture, texture_coords);
    vec2 size = textureSize(sdf_texture, 0);
    float dist = pixel.z / (min(size.x, size.y) / 2);
    return vec4(vec3(fract(distance(texture_coords * size, pixel.xy))), 1);
}

#endif