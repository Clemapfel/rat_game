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
    vec2 pos = vertex_position * 0.5 + 0.5; // Transform from [-1,1] to [0,1]
    float scale = 20.0; // Scale of the triangles
    vec2 c = pos * scale;

    // Create a hexagonal grid
    float line_width = 0.05; // Width of the lines
    vec2 p = mod(c, vec2(1.0, sqrt(3.0)/2.0)) - vec2(0.5, sqrt(3.0)/4.0);
    if (p.x < 0.0) p.x += 1.0;
    if (p.y < 0.0) p.y += sqrt(3.0)/2.0;

    // Determine the region in the hexagon
    vec2 q;
    if (p.x > 0.75) {
        q = p - vec2(0.75, sqrt(3.0)/4.0);
    } else if (p.y > sqrt(3.0)/4.0) {
        q = p - vec2(0.25, sqrt(3.0)/4.0);
    } else {
        q = p - vec2(0.5, 0.0);
    }

    // Draw lines
    float dist = length(q);
    if (dist < line_width) {
        return vec4(0.0, 0.0, 0.0, 1.0); // Line color
    } else {
        return vec4(1.0, 1.0, 1.0, 1.0); // Background color
    }
}

#endif
