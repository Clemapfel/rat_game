#pragma language glsl4

float gaussian(float x, float ramp)
{
    return exp(((-4 * 3.14159265359) / 3) * (ramp * x) * (ramp * x));
}

#ifdef PIXEL

struct Light {
    vec2 position;
    float intensity;
    vec3 color;
};

layout(std430) readonly buffer light_buffer {
    Light lights[];
};

uniform int n_lights;

vec4 effect(vec4 _, Image normals, vec2 texture_coords, vec2 vertex_position) {

    vec3 normal_raw = Texel(normals, texture_coords).rgb;
    normal_raw.y = 1 - normal_raw.y;
    vec3 normal = normalize(normal_raw * 2 - 1.0);

    float light_z = 0; //max(0, length(normal.xy));

    vec3 color = vec3(0);
    for (int i = 0; i < n_lights; ++i) {

        Light light = lights[i];

        vec2 light_position = light.position.xy;
        light_position.x += love_ScreenSize.y / love_ScreenSize.x;
        vec3 light_direction = vec3(light.position.xy - vertex_position, light_z);
        float value = max(dot(normal, normalize(light_direction)), 0);
        vec3 light_color = light.color.rgb;

        float attenuation = gaussian(distance(
            light.position.xy / love_ScreenSize.xy,
            vertex_position.xy / love_ScreenSize.xy
        ), 1) * light.intensity;

        color += light_color * attenuation * value;
    }

    color = clamp(color, vec3(0), vec3(1));

    return vec4(color, 1);
}

#endif