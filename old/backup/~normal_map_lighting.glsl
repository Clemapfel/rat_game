#pragma language glsl4
#ifdef PIXEL

float gaussian(float x, float ramp)
{
    return exp(((-4 * 3.14159265359) / 3) * (ramp * x) * (ramp * x));
}

struct Light {
    vec2 position;
    float intensity;
    vec3 color;
};

layout(std430) readonly buffer n_done_counter {
    Light lights[];
};

uniform int n_lights;

uniform vec3 light_position; // Define the light position as a uniform
const float ambient_intensity = 0.2; // Set ambient intensity for ambient lighting
const vec4 light_color = vec4(1, 1, 1, 1);
const vec4 ambient_color = vec4(1, 1, 1, 1);
const vec3 attenuation_coefficients = vec3(0, 0, 1); // constant, linear, and quadratic terms

vec4 effect(vec4 vertex_color, Image normals, vec2 texture_coords, vec2 vertex_position)
{
    vec3 normal_map = Texel(normals, texture_coords).rgb;
    normal_map.y = 1 - normal_map.y;

    const float light_z = 30;
    vec3 light_direction = vec3(light_position.xy - vertex_position, light_z);
    light_direction.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec3 N = normalize(normal_map * 2.0 - 1.0);
    vec3 L = normalize(light_direction);

    vec3 diffuse = max(dot(N, L), 0.0) * light_color.rgb * light_color.a;

    float attenuation = gaussian(distance(
        light_position.xy / love_ScreenSize.xy,
        vertex_position.xy / love_ScreenSize.xy
    ), 1);

    return vec4(diffuse * attenuation, 1);
}

#endif