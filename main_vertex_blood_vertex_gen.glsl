layout(std430) buffer segments_buffer {
    vec4 segments[];
};

layout(std430) buffer is_valid_buffer {
    uint is_valid[];
};

layout(r32f) uniform image2D image;
uniform int image_width;
uniform int image_height;
uniform float threshold;

vec2 interpolate(vec2 p1, vec2 p2, float val1, float val2) {
    float t = (threshold - val1) / (val2 - val1);
    return mix(p1, p2, t);
}

const ivec2 offsets[4] = ivec2[](ivec2(0, 0), ivec2(1, 0), ivec2(1, 1), ivec2(0, 1));
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    ivec2 global_id = ivec2(gl_GlobalInvocationID.xy);

    if (global_id.x >= image_width - 1 || global_id.y >= image_height - 1) {
        return;
    }

    float values[4];
    for (int i = 0; i < 4; ++i) {
        values[i] = imageLoad(image, global_id + offsets[i]).r;
    }

    int case_index = 0;
    for (int i = 0; i < 4; ++i) {
        if (values[i] > threshold) {
            case_index |= (1 << i);
        }
    }

    vec2 p1, p2;
    switch (case_index) {
        case 1:
        case 14:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            p2 = interpolate(global_id + offsets[0], global_id + offsets[1], values[0], values[1]);
            break;
        case 2:
        case 13:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[1], values[0], values[1]);
            p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            break;
        case 3:
        case 12:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            break;
        case 4:
        case 11:
            p1 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            p2 = interpolate(global_id + offsets[2], global_id + offsets[3], values[2], values[3]);
            break;
        case 5:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[1], values[0], values[1]);
            p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            segments[global_id.y * image_width + global_id.x] = vec4(p1, p2);
            p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            p2 = interpolate(global_id + offsets[2], global_id + offsets[3], values[2], values[3]);
            break;
        case 6:
        case 9:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            break;
        case 7:
        case 8:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            p2 = interpolate(global_id + offsets[2], global_id + offsets[3], values[2], values[3]);
            break;
        case 10:
            p1 = interpolate(global_id + offsets[0], global_id + offsets[1], values[0], values[1]);
            p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            segments[global_id.y * image_width + global_id.x] = vec4(p1, p2);
            p1 = interpolate(global_id + offsets[2], global_id + offsets[3], values[2], values[3]);
            p2 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
            break;
    }


    is_valid[global_id.y * image_width + global_id.x] = uint(p1 != vec2(0) && p2 != vec2(0));
    segments[global_id.y * image_width + global_id.x] = vec4(p1, p2);
}