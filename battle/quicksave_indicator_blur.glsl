#ifdef PIXEL

#define PI 3.1415926535897932384626433832795
float gaussian(float x, float ramp) {
    return exp(-1 * (ramp * x * ramp * x));
}

uniform float radius;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 fragment_position) {
    vec2 pixel_size = 1.0 / love_ScreenSize.xy;

    vec4 color = vec4(0.0);
    float weight_sum = 0.0;
    const float sigma = 2;

    for (float y = -radius; y <= radius; y++)
    {
        for (float x = -radius; x <= radius; x++)
        {
            vec2 offset = vec2(x, y) * pixel_size;
            float distance = length(vec2(x, y)) / radius;
            float weight = gaussian(distance, sigma);

            color += Texel(image, texture_coords + offset) * weight;
            weight_sum += weight;
        }
    }

    return color / weight_sum;
}

#endif