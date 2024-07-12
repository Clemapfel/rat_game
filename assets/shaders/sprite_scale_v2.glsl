vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords)
{
    // src: https://www.shadertoy.com/view/ltfXWS
    // modify texture coords such that the resulting image will have no artifacting
    // note that linear scaling mode has to be enabled
    vec2 texsize = vec2(textureSize(tex, 0));
    vec2 uv_texspace = texture_coords * texsize;
    vec2 seam = floor(uv_texspace + 0.5);
    uv_texspace = (uv_texspace - seam) / fwidth(uv_texspace) + seam;
    uv_texspace = clamp(uv_texspace, seam - .5, seam + .5);
    texture_coords = uv_texspace / texsize;

    return Texel(tex, texture_coords) * color;
}