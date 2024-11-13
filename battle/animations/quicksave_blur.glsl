float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (2.0 * 3.14159265359 * sigma * sigma);
}

#ifdef PIXEL


uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

uniform int kernel_size = 3;
vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    /*
    const float step = 1.0;
    int radius = int(kernel_size);
    vec3 color_sum = vec3(0.0);
    float weight_sum = 0.0;

    vec2 size = textureSize(image, 0);
    float sigma = float(radius) / 3.0; // Adjust sigma based on the radius

    for (float x = -radius; x <= radius; x += step)
    {
        for (float y = -radius; y <= radius; y += step)
        {
            vec2 offset = vec2(x, y) / size;
            float weight = gaussian(length(vec2(x, y)), sigma);
            color_sum += texture(image, texture_coords + offset).rgb * weight;
            weight_sum += weight;
        }
    }
        return vec4(color_sum / weight_sum, 1.0);
    */
stash
    vec4 color = texture2D(image, texture_coords) * weight[0];
    for (int i = 1; i < 3; i++) {
        color += texture2D(image, (texture_coords + vec2(0.0, offset[i] / love_ScreenSize.y))) * weight[i];
        color += texture2D(image, (texture_coords - vec2(0.0, offset[i] / love_ScreenSize.y))) * weight[i];
    }

    return color;
}
#endif