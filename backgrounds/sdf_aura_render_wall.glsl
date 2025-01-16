
#ifdef PIXEL

uniform float threshold;

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture(image, texture_coords);
    const float eps = 0.15;
    float threshold_override = 0.9;
    float value = smoothstep(threshold_override - eps, threshold_override + eps, pixel.a);
    vec3 as_hsv = rgb_to_hsv(pixel.rgb);
    as_hsv.z = 1;
    as_hsv.y = 1;
    return vec4(hsv_to_rgb(as_hsv), value);
}

#endif