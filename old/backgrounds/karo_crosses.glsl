#define PI 3.1415926535897932384626433832795

float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

float sine_wave(float x, float frequency) {
    return (sin(2.0 * 3.14159 * x * frequency - 3.14159 / 2.0) + 1.0) * 0.5;
}

vec2 rotate_point(vec2 point, vec2 pivot, float angle_dg)
{
    float angle = angle_dg * (3.14159 / 180.0);

    float s = sin(angle);
    float c = cos(angle);

    point -= pivot;
    point.x = point.x * c - point.y * s;
    point.y = point.x * s + point.y * c;
    point += pivot;

    return point;
}

vec3 lch_to_rgb(vec3 lch) {
    float L = lch.x * 100.0;
    float C = lch.y * 100.0;
    float H = lch.z * 360.0;

    float a = cos(radians(H)) * C;
    float b = sin(radians(H)) * C;

    float Y = (L + 16.0) / 116.0;
    float X = a / 500.0 + Y;
    float Z = Y - b / 200.0;

    X = 0.95047 * ((X * X * X > 0.008856) ? X * X * X : (X - 16.0 / 116.0) / 7.787);
    Y = 1.00000 * ((Y * Y * Y > 0.008856) ? Y * Y * Y : (Y - 16.0 / 116.0) / 7.787);
    Z = 1.08883 * ((Z * Z * Z > 0.008856) ? Z * Z * Z : (Z - 16.0 / 116.0) / 7.787);

    float R = X *  3.2406 + Y * -1.5372 + Z * -0.4986;
    float G = X * -0.9689 + Y *  1.8758 + Z *  0.0415;
    float B = X *  0.0557 + Y * -0.2040 + Z *  1.0570;

    R = (R > 0.0031308) ? 1.055 * pow(R, 1.0 / 2.4) - 0.055 : 12.92 * R;
    G = (G > 0.0031308) ? 1.055 * pow(G, 1.0 / 2.4) - 0.055 : 12.92 * G;
    B = (B > 0.0031308) ? 1.055 * pow(B, 1.0 / 2.4) - 0.055 : 12.92 * B;

    return vec3(clamp(R, 0.0, 1.0), clamp(G, 0.0, 1.0), clamp(B, 0.0, 1.0));
}

// src: https://www.shadertoy.com/view/3sdcWH

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float noise(vec2 v)
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

uniform float elapsed;


//returns the min- and max-corners of the rectangle of the crossing 'c'
vec4 crossingToRectangle(vec2 c){
    float time = elapsed / 10;
    vec4 d = vec4(
        noise(c + vec2(-1 * time, -1 * time)),
        noise(c + vec2(+1 * time, +1 * time)),
        noise(c + vec2(-1 * time, +1 * time)),
        noise(c + vec2(+1 * time, +1 * time))
    );

    // orientation of this crossing
    int o = int(c.x+c.y) & 1;
    if(o==1) d = d.wxyz;

    return d + vec4(c-1.,c);
}

//find the crossing of the rectangle in which the point 'p' lays
vec2 getCrossing(vec2 p){

    vec2 i = floor(p);
    vec2 f = i - p;

    // this variable will tell us the coordinate of the crossing relative to the cell coordinate
    vec2 c = vec2(0);

    // orientation of this cell
    int o = int(i.x+i.y) & 1;
    // if o=0 then u=1 and vice versa
    int u = o ^ 1;
    // on which side of the line in this cell is the current point 'p'
    bool s = f[o] > noise(i);

    // magic
    if(s) c[o] = 1.;
    vec2 n = i;
    n[o] += s ? 1. : -1.;
    if(f[u]>noise(n)) c[u] = 1.;

    return i+c;
}

//gets the rectangle in which the point 'p' lays
vec4 getRectangle(vec2 p){
    return crossingToRectangle(getCrossing(p));
}


float smooth_max(float a, float b, float smoothness) {
    float h = exp(smoothness * a) + exp(smoothness * b);
    return log(h) / smoothness;
}

#ifdef PIXEL


vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 10;

    // COOKING

    float aspect_factor = love_ScreenSize.x / love_ScreenSize.y;
    vec2 position = vertex_position / love_ScreenSize.xy;
    vec2 center = vec2(0.5);

    const float scale = 6;
    position *= scale;
    center *= scale;
    position.x *= aspect_factor;
    center.x *= aspect_factor;

    position += elapsed / 2;
    center += elapsed / 2;

    position = rotate_point(position, center, distance(position, center) * (sin(elapsed) * PI * 0.5));

    vec4 rectangle = getRectangle(position);
    vec2 min_corner = rectangle.xy;
    vec2 max_corner = rectangle.zw;

    float distance_min_corner = min(abs(position - min_corner).x, abs(position - min_corner).y); //distance to min corner
    float distance_max_corner = min(abs(position - max_corner).x, abs(position - max_corner).y); //distance to max corner
    float dist = min(distance_min_corner, distance_max_corner);

    float value = smoothstep(sine_wave(elapsed / 5, 1) * 0.05 ,  0.2, sin(dist)) * 0.8 * noise(rectangle.xy / 7);

    vec2 f = fract(position);
    const float boundary = 0.2;
    float grid = mix(smoothstep(-boundary, 2 * boundary, min(f.x, f.y) * value), smoothstep(-boundary, 2 * boundary, min(1 - f.x, 1 - f.y) * value), 0.5);
    float hue_time = elapsed / 3;

    vec2 outline_f = fract(position);
    float outline = mix(
        smoothstep(0, 0.03, fract(min(outline_f.x, outline_f.y))),
        smoothstep(0, 0.03, fract(min(1 - outline_f.x, 1 - outline_f.y))),
    0.5);

    return vec4(lch_to_rgb(vec3(
        0.7,
        1.0,
        fract(grid + elapsed / 10)
    )) - vec3(1 - outline) * 0.9, 1);

}

#endif
