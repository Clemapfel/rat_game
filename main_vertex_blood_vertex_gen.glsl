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

const ivec2 offsets[4] = ivec2[](ivec2(0, 0), ivec2(1, 0), ivec2(1, 1), ivec2(0, 1));

// Precomputed interpolation offsets for each case index
const ivec2 segment_offsets[16][2] = ivec2[][](
ivec2[](ivec2(-1, -1), ivec2(-1, -1)), // case 0
ivec2[](ivec2(0, 3), ivec2(0, 1)),     // case 1
ivec2[](ivec2(0, 1), ivec2(1, 2)),     // case 2
ivec2[](ivec2(0, 3), ivec2(1, 2)),     // case 3
ivec2[](ivec2(1, 2), ivec2(2, 3)),     // case 4
ivec2[](ivec2(0, 1), ivec2(2, 3)),     // case 5 (ambiguous)
ivec2[](ivec2(0, 3), ivec2(1, 2)),     // case 6
ivec2[](ivec2(0, 3), ivec2(2, 3)),     // case 7
ivec2[](ivec2(0, 3), ivec2(2, 3)),     // case 8
ivec2[](ivec2(0, 3), ivec2(1, 2)),     // case 9
ivec2[](ivec2(0, 1), ivec2(2, 3)),     // case 10 (ambiguous)
ivec2[](ivec2(1, 2), ivec2(2, 3)),     // case 11
ivec2[](ivec2(0, 3), ivec2(1, 2)),     // case 12
ivec2[](ivec2(0, 1), ivec2(1, 2)),     // case 13
ivec2[](ivec2(0, 3), ivec2(0, 1)),     // case 14
ivec2[](ivec2(-1, -1), ivec2(-1, -1))  // case 15
);

vec2 interpolate(vec2 p1, vec2 p2, float val1, float val2) {
    if (abs(val2 - val1) < 1e-5) return (p1 + p2) * 0.5; // Avoid division by zero
    float t = (threshold - val1) / (val2 - val1);
    return mix(p1, p2, t);
}

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
void computemain() {
    ivec2 global_id = ivec2(gl_GlobalInvocationID.xy);

    if (global_id.x >= image_width - 1 || global_id.y >= image_height - 1) {
        return;
    }

    float values[4];
    for (int i = 0; i < 4; ++i) {
        values[i] = imageLoad(image, global_id + offsets[i]).r;
    }

    int case_index = int(values[0] > threshold) |
    (int(values[1] > threshold) << 1) |
    (int(values[2] > threshold) << 2) |
    (int(values[3] > threshold) << 3);

    ivec2 seg1 = segment_offsets[case_index][0];
    ivec2 seg2 = segment_offsets[case_index][1];

    vec2 p1 = vec2(0), p2 = vec2(0);
    bool valid_segment = seg1.x != -1 && seg2.x != -1;

    if (valid_segment) {
        p1 = interpolate(global_id + offsets[seg1.x], global_id + offsets[seg1.y], values[seg1.x], values[seg1.y]);
        p2 = interpolate(global_id + offsets[seg2.x], global_id + offsets[seg2.y], values[seg2.x], values[seg2.y]);

        // Handle ambiguous cases (5 and 10)
        if (case_index == 5 || case_index == 10) {
            float avg = (values[0] + values[1] + values[2] + values[3]) * 0.25;
            if (avg <= threshold) {
                p1 = interpolate(global_id + offsets[0], global_id + offsets[3], values[0], values[3]);
                p2 = interpolate(global_id + offsets[1], global_id + offsets[2], values[1], values[2]);
            }
        }
    }

    is_valid[global_id.y * image_width + global_id.x] = uint(valid_segment && p1 != p2);
    segments[global_id.y * image_width + global_id.x] = vec4(p1, p2);
}