#pragma language glsl4

#ifdef VERTEX

struct Particle {
    vec2 current_position;
    vec2 last_position;
    float radius;
    float color;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
};

varying float value;

vec4 position(mat4 transform, vec4 vertex_position)
{
    Particle particle = particles[love_InstanceID];
    vertex_position.xy += particle.current_position;
    value = particle.color;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

varying float value;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec3 as_hsv = vertex_color.rgb; // vertex color encoded as hsv to save one conversion
    as_hsv.z = value;
    return vec4(hsv_to_rgb(as_hsv), 1) * Texel(image, texture_coords);
}
#endif