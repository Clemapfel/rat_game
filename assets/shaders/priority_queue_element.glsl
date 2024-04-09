#pragma language glsl3

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

uniform int _is_knocked_out;
uniform int _is_dead;

vec4 effect(vec4 vertex_color, Image tex, vec2 texture_coords, vec2 vertex_position)
{
    vec4 color = Texel(tex, texture_coords) * vertex_color;
    if (_is_dead + _is_knocked_out == 0)
            return color;

    vec3 as_hsv = rgb_to_hsv(color.rgb);

    if (_is_dead == 1)
    {
        // dead: grayscale + darken
        as_hsv.y = 0;
        as_hsv.z = clamp(as_hsv.z - 0.2, 0, 1);
        return vec4(hsv_to_rgb(as_hsv), color.a);
    }
    else if (_is_knocked_out == 1)
    {
        // knocked out: monochrome red
        as_hsv.x = 0;
        as_hsv.y = clamp(as_hsv.y + 0.3, 0, 1);
        return vec4(hsv_to_rgb(as_hsv), color.a);
    }
    else
    {
        return color; // unreachable
    }
}