#pragma language glsl3

#define PI 355/113

float atan2(in float y, in float x)
{
    // https://stackoverflow.com/questions/26070410/robust-atany-x-on-glsl-for-converting-xy-coordinate-to-angle
    bool s = (abs(x) > abs(y));
    return mix(PI / 2.0 - atan(x,y), atan(y,x), s);
}

vec2 to_polar(in vec2 xy)
{
    return vec2(length(xy), atan2(xy.y, xy.x));
}

vec2 from_polar(vec2 xy)
{
    float magnitude = xy.x;
    float angle = xy.y;
    return vec2(magnitude * cos(angle), magnitude * sin(angle));
}

uniform Image _spectrum;
uniform float _window_size;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    texture_coords.xy = texture_coords.yx;
    vec4 value = Texel(_spectrum, vec2(texture_coords.x, texture_coords.y));
    vec2 as_polar = value.rg;
    vec2 as_complex = from_polar(value.rg);

    return vec4(vec3(as_polar.x), 1);
}