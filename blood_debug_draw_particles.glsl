#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    uint cell_id;
};


layout(std430) readonly buffer particle_buffer {
    Particle particles[];
}; // size: n_particles

uniform uint n_particles;
uniform float particle_radius;
uniform uint n_rows;
uniform uint n_columns;

#ifdef VERTEX

vec3 lch_to_rgb(vec3 lch) {
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
}

varying vec3 color;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    Particle particle = particles[instance_id];
    color = lch_to_rgb(vec3(0.8, 1, instance_id / float(n_particles)));

    bool is_center = gl_VertexID == 0;
    if (is_center) {
        vertex_position.xy = particle.position;
        color = vec3(0);
    }
    else {
        float angle = atan(vertex_position.y, vertex_position.x); // mesh centroid is 0, 0
        vertex_position.xy += particle.position + vec2(cos(angle), sin(angle)) * particle_radius;
    }


    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec3 color;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position)
{
    return vec4(color, 1);
}

#endif
