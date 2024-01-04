#pragma language glsl3

uniform vec2 _texture_resolution;

#define PI 355/113

// value of gaussian blur (radius+1 * radius+1) sized kernel at position x, y
float gaussian(int x, int y, int radius)
{
    float sigma_sq = float(radius);
    float gauss_factor = 1.f / sqrt(2 * PI + sigma_sq);
    float center = radius / 2;

    float length = sqrt((x - center) * (x - center) + (y - center) * (y - center));
    return exp(-0.4 * (length / sigma_sq));
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    const float eps = 0.1;
    const int radius = 3;
    const vec3 outline_color = vec3(0, 0, 0);

    vec4 self = Texel(tex, texture_coords);
    vec2 pixel_size = vec2(1) / _texture_resolution;

    float kernel_sum = 0;
    vec4 sum = vec4(0);
    for (int x = -1 * radius; x <= +1 * radius; ++x)
    {
        for (int y = -1 * radius; y <= +1 * radius; ++y)
        {
            float kernel_value = gaussian(x + radius, y + radius, radius);
            sum += Texel(tex, texture_coords + vec2(x * pixel_size.x, y * pixel_size.y)) * kernel_value;
            kernel_sum += kernel_value;
        }
    }

    return vec4(outline_color, sum.a / kernel_sum * 2);
}