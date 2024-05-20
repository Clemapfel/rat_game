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

uniform float r_offset;
uniform float g_offset;
uniform float b_offset;
uniform float h_offset;
uniform float s_offset;
uniform float v_offset;

uniform float r_factor;
uniform float g_factor;
uniform float b_factor;
uniform float h_factor;
uniform float s_factor;
uniform float v_factor;

uniform vec4 mix_color;
uniform float mix_weight;

uniform float opacity;
uniform vec4 black;

uniform bool invert;

#ifdef PIXEL

vec4 effect(vec4 _, Image texture, vec2 texture_coordinates, vec2 vertex_position)
{
    vec4 color = Texel(texture, texture_coordinates);

    vec3 as_rgb = color.rgb;
    as_rgb.r += r_offset;
    as_rgb.g += g_offset;
    as_rgb.b += b_offset;
    as_rgb.rgb = clamp(as_rgb.rgb, vec3(0), vec3(1));

    as_rgb.r *= r_factor;
    as_rgb.g *= g_factor;
    as_rgb.b *= b_factor;
    as_rgb.rgb = clamp(as_rgb.rgb, vec3(0), vec3(1));

    vec3 as_hsv = rgb_to_hsv(as_rgb);
    as_hsv.x += h_offset;
    as_hsv.y += s_offset;
    as_hsv.z += v_offset;
    as_hsv.xyz = clamp(as_hsv.xyz, vec3(0), vec3(1));

    as_hsv.x *= h_factor;
    as_hsv.y *= s_factor;
    as_hsv.z *= v_factor;
    as_hsv.xyz = clamp(as_hsv.xyz, vec3(0), vec3(1));

    as_rgb = hsv_to_rgb(as_hsv);

    color.rgb = as_rgb;

    color.rgb = mix(color.rgb, mix_color.rgb, clamp(mix_weight, 0, 1));
    color.rgb = clamp(color.rgb, black.rgb, vec3(1));
    if (invert) {
        color.rgb = vec3(1) - color.rgb;
    }

    color.a *= opacity;
    return color;
}

#endif
