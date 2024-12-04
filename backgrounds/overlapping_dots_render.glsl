#pragma language glsl4

struct InstanceData {
    vec2 center;
    uint quantized_radius; // as uint so it can be radix sorted
    float rotation;
    float hue;
};

layout(std430) readonly buffer instance_data_buffer {
    InstanceData instance_data[]; // size: n_instances
};

vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

vec3 lch_to_rgb(vec3 lch) {
    // Scale the input values
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    // Convert LCH to LAB
    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    // Convert LAB to XYZ
    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    // Convert XYZ to RGB
    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    // Apply gamma correction
    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
}

#ifdef VERTEX

varying vec4 color;
uniform uint radius_denominator;
uniform float max_radius;
uniform uint n_instances;

vec4 position(mat4 transform, vec4 vertex_position)
{
    uint instance_id = uint(love_InstanceID);
    InstanceData data = instance_data[instance_id];

    float omit_first = distance(vertex_position.xy, vec2(0)); // 0 for center, 1 for everything else
    float angle = atan(vertex_position.y, vertex_position.x) + data.rotation;
    float radius = float(data.quantized_radius) / float(radius_denominator) * max_radius;
    vertex_position.xy = translate_point_by_angle(data.center, radius * omit_first, angle);
    color.rgb = lch_to_rgb(vec3(0.8, 1, data.hue));
    color.a = 1;

    return transform * vertex_position;
}

#endif

#ifdef PIXEL

varying vec4 color;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    return color * vertex_color * Texel(image, texture_coords);
}
#endif