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

float sum(vec3 arg)
{
    return arg.x + arg.y + arg.z;
}

float sum(vec4 arg)
{
    return arg.x + arg.y + arg.z + arg.w;
}

#ifdef VERTEX

flat varying int _vertex_id;

vec4 position(mat4 transform, vec4 vertex_position)
{
    _vertex_id = gl_VertexID;
    return transform * vertex_position;
}

#endif

#ifdef PIXEL

uniform vec4 _text_color_rgba;
uniform float _time;
uniform float _rainbow_width;

flat varying int _vertex_id;

vec4 effect(vec4 vertex_color, Image tex, vec2 texture_coords, vec2 vertex_position)
{
    vec4 self = Texel(tex, texture_coords) * vertex_color;
    vec4 text_color = _text_color_rgba;
    float error = sum(abs(self.rgba - text_color.rgba));
    vec3 target = self.rgb * (1 - error);
    float time = _time;

    float hue = (_vertex_id / 4);
    hue /= _rainbow_width;
    vec3 rainbow = hsv_to_rgb(vec3(hue + time, 1, 1));
    return vec4(target * rainbow, self.a);
}

#endif