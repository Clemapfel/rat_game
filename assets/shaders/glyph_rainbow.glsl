//#pragma language glsl3

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

float sum(float arg)
{
    return arg;
}

float sum(vec2 arg)
{
    return arg.x + arg.y;
}

float sum(vec3 arg)
{
    return arg.x + arg.y + arg.z;
}

float sum(vec4 arg)
{
    return arg.x + arg.y + arg.z + arg.w;
}

// random
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float random(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
    0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0

    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float random(float x)
{
    return random(vec2(x));
}

#ifdef VERTEX

flat varying int _vertex_id;

uniform float _time;

vec4 position(mat4 transform, vec4 vertex_position)
{
    const float shake_offset = 6;
    const float shake_period = 15;

    _vertex_id = gl_VertexID;
    int letter_id = _vertex_id / 4;
    vec4 position = vertex_position;

    float i_offset = round(_time / (1 / shake_period));
    position.x += random(letter_id + i_offset) * shake_offset;
    position.y += random(letter_id + i_offset + 3.14159) * shake_offset;

    return transform * position;
}

#endif

#ifdef PIXEL

uniform vec4 _text_color_rgba;
uniform float _rainbow_width;
uniform float _time;

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