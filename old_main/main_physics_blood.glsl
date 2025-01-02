
#ifdef PIXEL

uniform float threshold = 0.5;

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture(image, texture_coords);
    const float eps = 0.1;
    return mix(vec4(0), color, smoothstep(threshold - eps, threshold + eps, length(pixel.a))) * vec4(pixel.rgb, 1);
}

#endif