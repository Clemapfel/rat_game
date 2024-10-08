//#pragma language glsl4

#ifdef PIXEL

#define PI 3.1415926535897932384626433832795

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

/// @see https://www.shadertoy.com/view/WtccD7


//////////////////////////////////////////////////////////////////////
// oklab transform and inverse from
// https://bottosson.github.io/posts/oklab/

/*
const mat3 fwdA = mat3(1.0, 1.0, 1.0,
                       0.3963377774, -0.1055613458, -0.0894841775,
                       0.2158037573, -0.0638541728, -1.2914855480);

const mat3 fwdB = mat3(4.0767245293, -1.2681437731, -0.0041119885,
                       -3.3072168827, 2.6093323231, -0.7034763098,
                       0.2307590544, -0.3411344290,  1.7068625689);

const mat3 invB = mat3(0.4121656120, 0.2118591070, 0.0883097947,
                       0.5362752080, 0.6807189584, 0.2818474174,
                       0.0514575653, 0.1074065790, 0.6302613616);

const mat3 invA = mat3(0.2104542553, 1.9779984951, 0.0259040371,
                       0.7936177850, -2.4285922050, 0.7827717662,
                       -0.0040720468, 0.4505937099, -0.8086757660);
*/

vec3 linear_srgb_from_oklab(vec3 c) {

    const mat3 fwdA = mat3(1.0, 1.0, 1.0,
    0.3963377774, -0.1055613458, -0.0894841775,
    0.2158037573, -0.0638541728, -1.2914855480);

    const mat3 fwdB = mat3(4.0767245293, -1.2681437731, -0.0041119885,
    -3.3072168827, 2.6093323231, -0.7034763098,
    0.2307590544, -0.3411344290,  1.7068625689);
    vec3 lms = fwdA * c;
    return fwdB * (lms * lms * lms);

}

// @param l lightness, [0, 1]
// @param c chroma [0, 1]
// @param h hue [0, 1]
vec3 oklch_to_rgb(vec3 lch)
{
    float theta = clamp(lch.z, 0, 1) * (2 * PI);
    float l = lch.x;
    float chroma = lch.y;
    float a = chroma * cos(theta);
    float b = chroma * sin(theta);
    vec3 c = vec3(l, a, b);

    const mat3 fwdA = mat3(1.0, 1.0, 1.0,
    0.3963377774, -0.1055613458, -0.0894841775,
    0.2158037573, -0.0638541728, -1.2914855480);

    const mat3 fwdB = mat3(4.0767245293, -1.2681437731, -0.0041119885,
    -3.3072168827, 2.6093323231, -0.7034763098,
    0.2307590544, -0.3411344290,  1.7068625689);
    vec3 lms = fwdA * c;
    return fwdB * (lms * lms * lms);
}

float angle(vec2 v)
{
    return (atan(v.y, v.x) + PI) / (2 * PI);
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

float project(float value, float lower, float upper) {
    return value * abs(upper - lower) + min(lower, upper);
}

float reverse_gaussian(float x, float c) {
    return -exp(-pow(x - 0.5, 2.0) / c) + 1.0;
}


float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

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

// ###

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 75;
    vec2 pos = vertex_position / love_ScreenSize.xy;

    pos -= vec2(0.5);
    pos *= 2.5;
    pos += vec2(0.5);
    pos -= vec2(0.5);
    pos.x *= love_ScreenSize.x / love_ScreenSize.y;

    // hue
    vec2 origin = vec2(random(pos + vec2(time, -time)), random(pos + vec2(-time, time)));
    float dist = length(pos - origin);
    float dg = fract(angle(pos - origin) + time);
    float hue = dg; //gaussian(dg, 0.5, 0.36);
    hue = mod(hue + time, 1);

    // value
    float value = reverse_gaussian(texture_coords.y - 0.3, 0.3);
    return vec4(lch_to_rgb(vec3(0.7, 1.0, hue)), 1);

    //return vec4(lch2rgb(vec3(0.77, 0.25, hue)), 1);
}

#endif


