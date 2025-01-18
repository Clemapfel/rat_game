#ifdef PIXEL

#define PI 3.1415926535897932384626433832795

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 effect(vec4, Image density, vec2 texture_coords, vec2) {
    vec4 data = texture(density, texture_coords);
    float angle = (atan(data.z, data.y) + PI) / (2 * PI);
    return vec4(hsv_to_rgb(vec3(angle, data.x, data.x)), 1);
}

#endif