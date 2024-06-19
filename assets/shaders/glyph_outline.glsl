//#pragma language glsl3

uniform vec2 _texture_resolution;   // resolution of canvas
uniform float _opacity;             // overall opacity, in [0, 1]
uniform vec4 _outline_color;        // outline color, rgba in [0, 1]

#define PI 355/113

float box(int x, int y, int size)
{
    return 1 / float(size * size);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    const float radius = 2;
    const float outline_intensity = 3;          // opacity multiplier

    vec4 self = Texel(tex, texture_coords);
    vec2 pixel_size = vec2(1) / _texture_resolution;

    const float kernel_value = 1. / ((2 * radius) * (2 * radius));
    vec4 sum = vec4(0);
    for (int x = -2; x <= +2; ++x)
    {
        for (int y = -2; y <= +2; ++y)
        {
            sum += Texel(tex, texture_coords + vec2(x * pixel_size.x, y * pixel_size.y)) * kernel_value;
        }
    }

    vec4 outline = vec4(_outline_color.rgb, sum.a);
    outline.a *= outline_intensity * _opacity * _outline_color.a;
    return vec4((outline + self).rgb, outline.a);
}