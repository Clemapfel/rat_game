#pragma glsl3

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

uniform float _r_offset;
uniform float _g_offset;
uniform float _b_offset;
uniform float _h_offset;
uniform float _s_offset;
uniform float _v_offset;
uniform float _a_offset;

uniform float _r_factor;
uniform float _g_factor;
uniform float _b_factor;
uniform float _h_factor;
uniform float _s_factor;
uniform float _v_factor;
uniform float _a_factor;

uniform vec4 _mix_color;
uniform float _mix_weight;

uniform vec4 _vertex_color;
uniform float _opacity;
uniform vec4 _black;

uniform bool _invert;

#ifdef VERTEX
vec4 position(mat4 transform, vec4 vertex_position)
{
    vec4 pos = vertex_position;
    return transform * pos;
}
#endif

#ifdef PIXEL

vec4 effect(vec4 _, Image texture, vec2 texture_coordinates, vec2 vertex_position)
{
    vec4 color = Texel(texture, texture_coordinates);

    if (_invert)
        color.rgb = vec3(1) - color.rgb;

    vec3 as_rgb = color.rgb;
    as_rgb *= vec3(_r_factor, _g_factor, _b_factor);
    as_rgb.r += _r_offset;
    as_rgb.g += _g_offset;
    as_rgb.b += _b_offset;
    as_rgb = clamp(as_rgb, vec3(0), vec3(1));

    vec3 as_hsv = rgb_to_hsv(as_rgb);
    as_hsv *= vec3(_h_factor, _s_factor, _v_factor);
    as_hsv.x += _h_offset;
    as_hsv.y += _s_offset;
    as_hsv.z += _v_offset;

    as_hsv = clamp(as_hsv, vec3(0), vec3(1));

    as_rgb = hsv_to_rgb(as_hsv);
    float alpha = clamp((color.a * _a_factor) + _a_offset, 0, 1);

    if (color.a < 1 / 256.f)
        return vec4(0);

    vec4 result = vec4(as_rgb, alpha) * vec4(1);
    result = mix(result, _mix_color, clamp(_mix_weight, 0, 1));

    result *= _vertex_color * vec4(1, 1, 1, _opacity);
    result = clamp(result, _black, vec4(1));
    return result;
}

#endif
