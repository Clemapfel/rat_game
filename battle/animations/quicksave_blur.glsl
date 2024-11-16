#version 330 core

uniform int kernel_size;

float gaussian(float x, float sigma) {
    return exp(-0.5 * (x * x) / (sigma * sigma)) / (sigma * sqrt(2.0 * 3.14159265));
}

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 frag_position)
{
    int half_size = kernel_size / 2;
    vec3 color_sum = vec3(0.0);
    float weight_sum = 0.0;

    for (int i = -half_size; i <= half_size; i++) {
        for (int j = -half_size; j <= half_size; j++) {
            vec2 offset = vec2(float(i), float(j)) / textureSize(input_image, 0);
            float weight = gaussian(length(offset), 2);
            color_sum += texture(input_image, tex_coords + offset).rgb * weight;
            weight_sum += weight;
        }
    }

    return vec4(color_sum / weight_sum, 1.0);
}

/*
#ifdef PIXEL

uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

uniform bool horizontal_or_vertical;
uniform vec2 texture_size;  // size of the texture

// src: https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 frag_position)
{
    vec4 color = Texel(image, frag_position / texture_size.xy) * weight[0];
    if (horizontal_or_vertical) {
        for (int i = 1; i < 3; i++) {
            float offset = offset[i] / texture_size.y;
            color += texture(image, (texture_coords + vec2(0.0, offset))) * weight[i];
            color += texture(image, (texture_coords - vec2(0.0, offset))) * weight[i];
        }
    }
    else {
        for (int i = 1; i < 3; i++) {
            float offset = offset[i] / texture_size.x;
            color += texture(image, (texture_coords + vec2(offset, 0.0))) * weight[i];
            color += texture(image, (texture_coords - vec2(offset, 0.0))) * weight[i];
        }
    }

    return color;
}
#endif

*/