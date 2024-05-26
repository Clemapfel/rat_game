#pragma language glsl4

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


vec3 srgb_from_linear_srgb(vec3 x) {

    vec3 xlo = 12.92*x;
    vec3 xhi = 1.055 * pow(x, vec3(0.4166666666666667)) - 0.055;

    return mix(xlo, xhi, step(vec3(0.0031308), x));

}

vec3 linear_srgb_from_srgb(vec3 x) {

    vec3 xlo = x / 12.92;
    vec3 xhi = pow((x + 0.055)/(1.055), vec3(2.4));

    return mix(xlo, xhi, step(vec3(0.04045), x));

}

//////////////////////////////////////////////////////////////////////
// oklab transform and inverse from
// https://bottosson.github.io/posts/oklab/


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

vec3 oklab_from_linear_srgb(vec3 c) {

    vec3 lms = invB * c;

    return invA * (sign(lms)*pow(abs(lms), vec3(0.3333333333333)));

}

vec3 linear_srgb_from_oklab(vec3 c) {

    vec3 lms = fwdA * c;

    return fwdB * (lms * lms * lms);

}

vec3 oklab_to_rgb(vec3 c) {

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

// ###

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 50;
    vec2 pos = vertex_position / love_ScreenSize.xy;

    pos -= vec2(0.5);
    pos *= 1.7;
    pos += vec2(0.5);
    pos -= vec2(0.5);
    pos.x *= love_ScreenSize.x / love_ScreenSize.y;

    // hue
    vec2 origin = vec2(random(pos + vec2(time, -time)), random(pos + vec2(-time, time)));
    float dist = length(pos - origin);
    float dg = fract(angle(pos - origin) + 0.75 + time);
    float hue = gaussian(dg, 0.5, 0.7);

    // value
    float value = reverse_gaussian(texture_coords.y - 0.3, 0.3);

    float theta = mod(2. * PI * (hue), 2 * PI) ;
    float L = 0.8;
    float chroma = 0.2;
    float a = chroma*cos(theta);
    float b = chroma*sin(theta);
    vec3 lab = vec3(L, a, b);
    vec3 rgb = clamp(linear_srgb_from_oklab(lab), 0.0, 1.0);

    return vec4(lab_to_rgb, 1);

    //return vec4(lch2rgb(vec3(0.77, 0.25, hue)), 1);
}

#endif

/*
// translate by angle
vec2 translate_point_by_angle(vec2 xy, float dist, float angle)
{
    return xy + vec2(cos(angle), sin(angle)) * dist;
}

// angle in [0, 1] to radian in [-pi, pi]
float angle_to_radians(float v) {
    return (v * 2 * PI) - PI ;
}

uniform float elapsed;
uniform vec2 texture_size;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 8;
    float dist = length(texture_coords - vec2(0.5));
    float dg = angle(texture_coords - vec2(0.5));

    float rng = random(texture_coords) ;
    vec2 warped_pos = translate_point_by_angle(texture_coords, time, angle_to_radians(-1 * dg));
    vec3 as_hsv = vec3(angle(warped_pos - vec2(0.5)), 1, 1);

    return Texel(image, warped_pos);
}
*/


