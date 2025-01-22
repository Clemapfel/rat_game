#pragma language glsl4

#ifdef PIXEL

#define PI 3.1415926535897932384626433832795


// Light properties
const vec3 light_color = vec3(1);

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/*
float density_falloff(float x) {
    const float n = 1;
    return exp(-2 * n * x * x);
}
*/
const float min_density = 1;

float density_falloff(float x) {
    return (min_density + 1.0 + log(max(x, 0.0001)) / 2.0);
}

float light_falloff(float x) {
    const float ramp = 0.1;
    const float peak = 2;
    return (1 - exp(-2 * ramp * x * x)) * peak;
}

vec4 effect(vec4 color, Image density_image, vec2 texture_coords, vec2 screen_coords) {
    vec4 data = texture(density_image, texture_coords);
    float density = clamp(data.x, 0, 1);
    vec2 dxy = data.yz; // directional derivative of surface

    float light_strength = 0.5;
    vec3 light_direction = normalize(vec3(0, -1.0, light_strength));

    vec3 normal = normalize(vec3(-dxy.x, -dxy.y, 1.0)) * 1.5;
    float diffuse = dot(normal, light_direction);
    float specular = pow(max(dot(normal, light_direction), 0.0), 32);
    float value =(diffuse + specular) - light_falloff(density);

    const float water_surface_eps = 0.15;
    return vec4(vec3(value), smoothstep(0.1, 0.1 + water_surface_eps, min(density_falloff(density), 1)));
}

#endif