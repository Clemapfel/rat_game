#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_hash;
};

layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform uint n_particles;
uniform float delta;
uniform sampler2D wall_texture;
uniform sampler2D sdf_texture;

#ifdef VERTEX

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    Particle particle = particles[instance_id];
    vertex_position.xy += particle.position + particle.velocity * delta;
    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL
vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 texel = texture(image, texture_coords);
    return vec4(texel.r);
    /*
    if (texture(wall_texture, vertex_position / love_ScreenSize.xy).r > 0.01)
        return vec4(0);
    else
        return vec4(texel.r) * texture(sdf_texture, vertex_position / love_ScreenSize.xy).z;
        */
}

#endif
