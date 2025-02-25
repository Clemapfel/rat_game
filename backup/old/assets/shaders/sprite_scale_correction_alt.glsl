uniform vec2 texture_resolution;

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 px)
{
    vec2 texel_size = vec2(1.0) / texture_resolution;

    vec2 ddx = dFdx(uv);
    vec2 ddy = dFdy(uv);
    vec2 fw = abs(ddx) + abs(ddy); // size of the screen pixel in uv

    vec2 xy = uv * texture_resolution;
    vec2 xy_floor = round(xy) - vec2(0.5);
    vec2 f = xy - xy_floor;
    vec2 f_uv = f * texel_size - vec2(0.5) * texel_size;

    f = clamp(f_uv / fw + vec2(0.5), 0.0, 1.0);

    uv = xy_floor * texel_size;

    // Since we already have the derivatives, might as well use textureGrad
    // instead of texture2D to improve performance. No other reason.
    return color * textureGrad(tex, uv + f * texel_size, ddx, ddy);
}

/*
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px)
{
    vec2 xy = uv * texture_resolution;
    vec2 xy_final = floor(xy) + min(fract(xy) / fwidth(xy), 1.0) - 0.5;
    return color * texture(tex, xy_final / texture_resolution);
}
*/

/*
uniform vec2 texture_resolution;
vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords)
{
    // src: https://www.shadertoy.com/view/ltfXWS
    // modify texture coords such that the resulting image will have less artifacting when upscaling
    vec2 uv_texspace = texture_coords * texture_resolution;
    vec2 seam = floor(uv_texspace + 0.5);
    uv_texspace = (uv_texspace - seam) / fwidth(uv_texspace) + seam;
    uv_texspace = clamp(uv_texspace, seam - 0.5, seam + 0.5);
    texture_coords = uv_texspace / texture_resolution;

    return Texel(tex, texture_coords) * color;
}
*/