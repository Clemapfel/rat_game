#pragma language glsl4

struct Branch {
    bool is_active;
    bool mark_active;
    vec2 position;
    vec2 velocity;
    float angular_velocity;
    float mass;
    float distance_since_last_split;
    uint next_index;
    bool has_split;
    uint split_depth;
};


uniform uint max_split_depth;
uniform float radius;

layout(std430) readonly buffer BranchBuffer {
    Branch branches[];
}; // size: n_branches

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
varying flat uint should_discard;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    Branch branch = branches[instance_id];
    should_discard = uint(!branch.is_active || (branch.mass <= 0));

    if (should_discard == 0) {
        color = lch_to_rgb(vec3(0.8, 1, branch.split_depth / float(max_split_depth)));

        if (gl_VertexID == 0)  // center
            vertex_position.xy += branch.position;
        else {
            float current_radius = branch.mass * radius;
            float angle = atan(vertex_position.y, vertex_position.x);
            vertex_position.xy += branch.position + vec2(cos(angle), sin(angle)) * current_radius;
        }
    }

    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL

varying vec3 color;
varying flat uint should_discard;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position)
{
    if (should_discard == 1)
        discard;

    return vec4(color, 1);
}

#endif