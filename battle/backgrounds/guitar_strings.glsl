#define PI 3.1415926535897932384626433832795

float voronoise(vec3 p, float blur) {
    blur = clamp(blur, 0, 1);
    float u = 0.55;
    float k = 1.0 + 63.0 * pow(1.0 - blur, 6.0);
    vec3 i = floor(p);
    vec3 f = fract(p);

    float s = 1.0 + 31.0 * blur;
    vec2 a = vec2(0.0, 0.0);

    vec3 g = vec3(-2.0);
    for (g.z = -2.0; g.z <= 2.0; g.z++)
    for (g.y = -2.0; g.y <= 2.0; g.y++)
    for (g.x = -2.0; g.x <= 2.0; g.x++) {
        vec3 v = i + g;
        v = fract(v * vec3(.1031, .1030, .0973));
        v += dot(v, v.yxz + 19.19);
        vec3 o = fract((v.xxy + v.yzz) * v.zyx) * vec3(u, u, 1.);
        vec3 d = g - f + o + 0.5;
        float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
        a += vec2(o.z * w, w);
    }
    return a.x / a.y;
}

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

float rope(float x) {
    if (x < 0)
        return 0.;
    else if (x > 1)
        return 0.;
    else
        return sqrt(cos(PI * x));
}

float rope2(float x) {
    return exp(-0.5 * (x - 0.5) * (x - 0.5));
}

float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float line_width = 0.01;
    float threshold = 0.5;
    const float n_lines = 6;
    float line_closeness = 4 + 2 * sin(elapsed);
    float hue_shift_time = elapsed / 5;

    vec2 pos = texture_coords.xy;

    float m = 2;
    float value_x = 5 * pos.x + elapsed;
    float value = sin(value_x) / (2 * m);
    //value *= voronoise(vec3(vec2(texture_coords.x), floor(value_x * 2)), 0.7);
    value += 0.5; // center

    vec3 res = vec3(0);
    for (int i = 0; i < n_lines; ++i)
    {
        float alpha = gaussian(abs(value - (pos.y + (i / (line_closeness * n_lines)) - (n_lines / 2 / (line_closeness * n_lines)))) / line_width, threshold);
        float hue = fract(i / n_lines + elapsed / 2);
        res = res + alpha * oklch_to_rgb(vec3(0.9, 0.2, hue));
        //res = res + alpha * hsv_to_rgb(vec3(hue, 1, 1));
    }

    return vec4(vec3(res), 1);
}

#endif
