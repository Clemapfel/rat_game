//#pragma language glsl3

uniform vec2 _texture_resolution;   // resolution of canvas
uniform float _opacity;             // overall opacity, in [0, 1]
uniform vec4 _outline_color;        // outline color, rgba in [0, 1]

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    const float outline_intensity = 3;          // opacity multiplier

    vec4 self = Texel(tex, texture_coords);
    vec2 pixel_size = vec2(1) / _texture_resolution;

    const float kernel_value = 1. / 9;
    vec4 sum = vec4(0);

    sum += Texel(tex, texture_coords + vec2(-2 * pixel_size.x, -2 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-2 * pixel_size.x, -1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-2 * pixel_size.x,  0)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-2 * pixel_size.x,  1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-2 * pixel_size.x, 2 * pixel_size.y)) * kernel_value;

    sum += Texel(tex, texture_coords + vec2(-1 * pixel_size.x, -2 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-1 * pixel_size.x, -1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-1 * pixel_size.x, +0)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-1 * pixel_size.x, 1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(-1 * pixel_size.x, 2 * pixel_size.y)) * kernel_value;

    //sum += Texel(tex, texture_coords) * kernel_value;

    sum += Texel(tex, texture_coords + vec2(1 * pixel_size.x, -2 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(1 * pixel_size.x, -1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(1 * pixel_size.x, 0)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(1 * pixel_size.x, 1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(1 * pixel_size.x, 2 * pixel_size.y)) * kernel_value;

    sum += Texel(tex, texture_coords + vec2(2 * pixel_size.x, -2 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(2 * pixel_size.x, -1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(2 * pixel_size.x, 0)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(2 * pixel_size.x, 1 * pixel_size.y)) * kernel_value;
    sum += Texel(tex, texture_coords + vec2(2 * pixel_size.x, 2 * pixel_size.y)) * kernel_value;

    vec4 outline = vec4(_outline_color.rgb, sum.a);
    outline.a *= outline_intensity * _opacity * _outline_color.a;
    return vec4((outline + self).rgb, outline.a);
}