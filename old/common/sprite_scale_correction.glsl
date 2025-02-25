uniform vec2 texture_resolution;

// https://github.com/Nikaoto/subpixel/blob/master/subpixel_grad.frag
vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 px)
{
    vec2 texel_size = vec2(1.0) / texture_resolution;

    vec2 ddx = dFdx(uv);
    vec2 ddy = dFdy(uv);
    vec2 fw = abs(ddx) + abs(ddy);

    vec2 xy = uv * texture_resolution;
    vec2 xy_floor = vec2(floor(xy.x + 0.5), floor(xy.y + 0.5)) - vec2(0.5);
    vec2 f = xy - xy_floor;
    vec2 f_uv = f * texel_size - vec2(0.5) * texel_size;

    f = clamp(f_uv / fw + vec2(0.5), 0.0, 1.0);
    uv = xy_floor * texel_size;

    return color * textureGrad(tex, uv + f * texel_size, ddx, ddy);
}