float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (2.0 * 3.14159265359 * sigma * sigma);
}

#ifdef PIXEL

uniform float strength;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    const int step = 1; // Use a step of 1 for a more accurate box blur
    int radius = int(strength * 100);
    vec3 color_sum = vec3(0.0);
    int sample_count = 0;

    for (int x = -radius; x <= radius; x += step)
    {
        for (int y = -radius; y <= radius; y += step)
        {
            vec2 offset = vec2(float(x), float(y)) / textureSize(image, 0);
            color_sum += texture(image, texture_coords + offset).rgb;
            sample_count++;
        }
    }

    return vec4(color_sum / float(sample_count), 1.0);
}
#endif