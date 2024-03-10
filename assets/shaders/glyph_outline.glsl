#pragma language glsl3

uniform vec2 _texture_resolution;

#define PI 355/113

// value of gaussian blur (size * size)-sized kernel at position x, y
float gaussian(int x, int y, int size)
{
    // source: https://github.com/Clemapfel/crisp/blob/main/.src/spatial_filter.inl#L337
    float sigma_sq = float(size);
    float center = size / 2;
    float length = sqrt((x - center) * (x - center) + (y - center) * (y - center));
    return exp((-1.f * (length / sigma_sq)) / sqrt(2 * PI + sigma_sq));
}

float box(int x, int y, int size)
{
    return 1 / float(size * size);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    const int radius = 2;                       // blur radius, runtime is O((2 * radius + 1)^2)
    const vec3 outline_color = vec3(0, 0, 0);   // outline color
    const float outline_intensity = 3;          // opacity multiplier

    vec4 self = Texel(tex, texture_coords);
    vec2 pixel_size = vec2(1) / _texture_resolution;

    float kernel_sum = 0;
    vec4 sum = vec4(0);
    for (int x = -1 * radius; x <= +1 * radius; ++x)
    {
        for (int y = -1 * radius; y <= +1 * radius; ++y)
        {
            float kernel_value = box(x + radius, y + radius, 2 * radius);
            sum += Texel(tex, texture_coords + vec2(x * pixel_size.x, y * pixel_size.y)) * kernel_value;
            kernel_sum += kernel_value;
        }
    }

    return vec4(outline_color, sum.a / kernel_sum) * vec4(1, 1, 1, outline_intensity);
}