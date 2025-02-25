#pragma language glsl4

struct Node {
    vec2 position;
    vec2 old_position;
    float mass;
};

layout(std430) readonly buffer node_buffer {
    Node nodes[];
}; // size: n_nodes

struct NodePair {
    uint a_index;
    uint b_index;
    float target_distance;
};

layout(std430) readonly buffer node_pair_buffer {
    NodePair node_pairs[];
}; // size: n_node_pairs

uniform float line_thickness = 5;

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

#define MODE_SEGMENTS 0
#define MODE_JOINTS 1

#ifndef MODE
#error "In rope_draw.glsl: MODE should be set to 0 or 1"
#endif

uniform uint n_instances;
uniform float delta = 1 / 60;

vec2 get_position(Node node) {
    return node.position;
    vec2 velocity = node.position - node.old_position;
    return node.position + velocity * delta * 0.5;
}

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    int instance_id = love_InstanceID;
    color = lch_to_rgb(vec3(0.8, 1, float(instance_id) / n_instances));

    #if MODE == MODE_SEGMENTS
        NodePair pair = node_pairs[instance_id];

        Node node_a = nodes[pair.a_index];
        Node node_b = nodes[pair.b_index];
    
        vec2 b_position = get_position(node_b);
        vec2 a_position = get_position(node_a);

        vec2 direction = normalize(b_position - a_position);
        vec2 perpendicular = vec2(-direction.y, direction.x);
        float half_thickness = line_thickness / 2.0;

        vec2 offset;
        uint vertex_id = gl_VertexID;
        if (vertex_id == 0) { // top left
            offset = -half_thickness * perpendicular;
        }
        else if (vertex_id == 1) { // top right
            offset = half_thickness * perpendicular;
        }
        else if (vertex_id == 2) { // bottom right
            offset = half_thickness * perpendicular + (b_position - a_position);
        }
        else if (vertex_id == 3) { // bottom left
            offset = -half_thickness * perpendicular + (b_position - a_position);
        }

        vec2 final_position = a_position + offset;
        return transform_projection * vec4(final_position, 0.0, 1.0);

    #elif MODE == MODE_JOINTS

        Node node = nodes[instance_id];
        vertex_position.xy += get_position(node);
        return transform_projection * vertex_position;

    #endif
}

#endif

#ifdef PIXEL

varying vec3 color;

vec4 effect(vec4 _, Image image, vec2 texture_coords, vec2 frag_position)
{
    return vec4(color, 1);
}

#endif