uniform vec2 texture_resolution;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px)
{
    // source: https://github.com/Nikaoto/subpixel/blob/master/subpixel_d7samurai.frag
    uv *= texture_resolution;
    uv = floor(uv) + min(fract(uv) / fwidth(uv), 1.0) - 0.5;
    uv /= texture_resolution;
    return color * texture(tex, uv);
}