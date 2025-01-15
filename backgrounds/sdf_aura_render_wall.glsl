
#ifdef PIXEL

uniform float threshold;

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture(image, texture_coords);
    const float eps = 0.15;
    float threshold_override = 0.8;
    float value = smoothstep(threshold_override - eps, threshold_override + eps, pixel.a);
    return vec4(mix(vec3(0), pixel.rgb, value), value);
}

#endif