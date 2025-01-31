
layout(rgba8) uniform image2D input_texture;

layout(std430) buffer vertex_buffer {
    vec2 positions[];
}; // size: (image_size.x - 1) * (image_size.y - 1)

uniform float threshold = 0.00;

float sample_field(ivec2 pos) {
    vec4 texel = imageLoad(input_texture, pos);
    return texel.r;
}

vec2 interpolate(ivec2 p1, ivec2 p2, float v1, float v2) {
    float t = (threshold - v1) / (v2 - v1);
    return mix(vec2(p1), vec2(p2), t);
}

layout(local_size_x = 16, local_size_y = 16) in; // dispatch with xy = texture_size / 16
void computemain(){
    
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    ivec2 image_size = imageSize(input_texture);
    if (pos.x >= image_size.x - 1 || pos.y >= image_size.y - 1)
        return;

    float v0 = imageLoad(input_texture, pos).a;
    float v1 = imageLoad(input_texture, pos + ivec2(1, 0)).a;
    float v2 = imageLoad(input_texture, pos + ivec2(1, 1)).a;
    float v3 = imageLoad(input_texture, pos + ivec2(0, 1)).a;

    // determine index for case
    int case_index = int(v0 > threshold) | (int(v1 > threshold) << 1) | (int(v2 > threshold) << 2) | (int(v3 > threshold) << 3);

    // compute intersection points based on the case index
    vec2 p0, p1;
    switch (case_index) {
        case 1:
        case 14:
            p0 = interpolate(pos, pos + ivec2(0, 1), v0, v3);
            p1 = interpolate(pos, pos + ivec2(1, 0), v0, v1);
            break;
        case 2:
        case 13:
            p0 = interpolate(pos, pos + ivec2(1, 0), v0, v1);
            p1 = interpolate(pos + ivec2(1, 0), pos + ivec2(1, 1), v1, v2);
            break;
        case 3:
        case 12:
            p0 = interpolate(pos, pos + ivec2(0, 1), v0, v3);
            p1 = interpolate(pos + ivec2(1, 0), pos + ivec2(1, 1), v1, v2);
            break;
        case 4:
        case 11:
            p0 = interpolate(pos + ivec2(1, 0), pos + ivec2(1, 1), v1, v2);
            p1 = interpolate(pos + ivec2(0, 1), pos + ivec2(1, 1), v3, v2);
            break;
        case 5:
            p0 = interpolate(pos, pos + ivec2(0, 1), v0, v3);
            p1 = interpolate(pos + ivec2(0, 1), pos + ivec2(1, 1), v3, v2);
            positions[pos.y * image_size.x + pos.x] = p0;
            positions[pos.y * image_size.x + pos.x + 1] = p1;
            p0 = interpolate(pos, pos + ivec2(1, 0), v0, v1);
            p1 = interpolate(pos + ivec2(1, 0), pos + ivec2(1, 1), v1, v2);
            break;
        case 6:
        case 9:
            p0 = interpolate(pos, pos + ivec2(1, 0), v0, v1);
            p1 = interpolate(pos + ivec2(0, 1), pos + ivec2(1, 1), v3, v2);
            break;
        case 7:
        case 8:
            p0 = interpolate(pos, pos + ivec2(0, 1), v0, v3);
            p1 = interpolate(pos + ivec2(0, 1), pos + ivec2(1, 1), v3, v2);
            break;
        case 10:
            p0 = interpolate(pos, pos + ivec2(1, 0), v0, v1);
            p1 = interpolate(pos + ivec2(0, 1), pos + ivec2(1, 1), v3, v2);
            positions[pos.y * image_size.x + pos.x] = p0;
            positions[pos.y * image_size.x + pos.x + 1] = p1;
            p0 = interpolate(pos, pos + ivec2(0, 1), v0, v3);
            p1 = interpolate(pos + ivec2(1, 0), pos + ivec2(1, 1), v1, v2);
            break;
        default:
            return; // no vertex, keep default buffer value of (-1, -1)
    }

    positions[pos.y * image_size.x + pos.x] = p0;
    positions[pos.y * image_size.x + pos.x + 1] = p1;
}