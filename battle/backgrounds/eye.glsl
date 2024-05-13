
#define PI 3.1415926535897932384626433832795


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

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
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

#ifdef PIXEL

uniform float elapsed;
uniform float hue;
uniform vec3 black;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 10;

    float aspect_factor = love_ScreenSize.x / love_ScreenSize.y;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos.x *= aspect_factor;

    vec2 rng_pos = pos - vec2(0.5 * aspect_factor, 0.5);
    rng_pos.x *= 5;
    rng_pos.y *= 10;
    float rng = distance(vec2(
         random(rng_pos + vec2(time, -time)),
         random(rng_pos + vec2(-time, time))
    ), rng_pos / 2);

    rng = gaussian(rng, 0, 1);

    vec2 center = vec2(0.5);
    center.x *= aspect_factor;
    float eye = clamp(sin(2 * PI * (1 - gaussian(distance(pos, center), 0, 0.03))), 0, 1);

    float ring_x = distance(pos, vec2(0.5 * aspect_factor, 0.5));
    rng *= (sin(8 * (ring_x) * 2 * PI + PI * time * 3)) + 1;

    vec3 as_rgb = vec3(rng);
    vec3 as_hsv = rgb_to_hsv(as_rgb);
    float hue_offset = 0.03;
    as_hsv.x = project(random(rng_pos), hue - hue_offset, hue + hue_offset);
    as_hsv.y = 1;

    float pupil = gaussian(distance(pos, center), 0, 0.01);
    as_hsv.y -= clamp(pupil, 0, 0.7);
    as_hsv.z += 3 * pupil;

    as_rgb = hsv_to_rgb(as_hsv);
    as_rgb -= vec3(eye);
    as_rgb -= vec3(2 * clamp(gaussian(distance(pos, center), 0, 0.02), 0, 1));

    as_rgb = clamp(as_rgb, black, vec3(1, 1, 1));
    return vec4(as_rgb, 1);
}

#endif
