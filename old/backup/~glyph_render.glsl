#pragma language glsl3

vec3 lch_to_rgb(vec3 lch) {
    // Scale the input values
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    // Convert LCH to LAB
    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    // Convert LAB to XYZ
    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    // Convert XYZ to RGB
    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    // Apply gamma correction
    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
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

float project(float value, float lower, float upper)
{
    return value * abs(upper - lower) + min(lower, upper);
}


// ###############################

uniform bool _shake_active;
uniform float _shake_offset; // rt.settings.glyph.shake_offset
uniform float _shake_period; // rt.settings.glyph.shake_period

uniform bool _wave_active;
uniform float _wave_period; // rt.settings.glyph.wave_period
uniform float _wave_offset; // rt.settings.glyph.wave_offset
uniform float _wave_speed;  // rt.settings.glyph.wave_speed

uniform bool _rainbow_active;
uniform int _rainbow_width; // rt.settings.glyph.rainbow_width

uniform int _n_visible_characters;
uniform float _time;

#ifdef VERTEX

flat varying int _letter_index;

#define PI 3.14159

vec4 position(mat4 transform, vec4 vertex_position)
{
    _letter_index = gl_VertexID / 4;

    vec4 position = vertex_position;

    if (_shake_active)
    {
        float i_offset = round(_time / (1 / _shake_period));
        position.x += project(random(_letter_index + i_offset), -1, 1) * _shake_offset;
        position.y += project(random(_letter_index + i_offset + 123.4567), -1, 1) * _shake_offset;
        // arbitary offset, just get any number different from the x result
    }

    if (_wave_active)
    {
        float x = ((_time / _wave_speed) + _letter_index);
        position.y += sin((x * 2 * PI) / _wave_period) * _wave_offset;
        // f(x) = sin((frequency * x * 2 * pi) / period) * amplitude
    }

    return transform * position;
}

#endif

#ifdef PIXEL

flat varying int _letter_index;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    if (_letter_index >= _n_visible_characters)
        discard;

    vec4 color = Texel(image, texture_coords) * vertex_color;

    if (_rainbow_active)
    {
        float time = _time;
        float hue = float(_letter_index) / _rainbow_width;
        vec3 rainbow = lch_to_rgb(vec3(0.75, 1, fract(hue + time)));
        color.rgb = color.rgb * rainbow;
    }

    return color;
}

#endif
