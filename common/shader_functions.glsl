#define PI 3.141592653
#define E  2.718281828

/// @brief convert rgb to hsv
vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

/// @brief convert rgba to hsva
vec4 rgba_to_hsva(vec4 rgba)
{
    return vec4(rgb_to_hsv(rgba.rgb), rgba.a);
}

/// @brief convert hsv to rgb
vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/// @brief convert hsva to rgba
vec4 hsva_to_rgba(vec4 hsva)
{
    return vec4(hsv_to_rgb(hsva.xyz), hsva.a);
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


/// @brief project value into given range
float project(float lower, float upper, float value)
{
    return value * abs(upper - lower) + min(lower, upper);
}

/// @brief rotate point around pivot
vec2 rotate_point(vec2 point, vec2 pivot, float angle_dg)
{
    float angle = angle_dg * (3.14159 / 180.0);

    float s = sin(angle);
    float c = cos(angle);

    // translate point back to origin:
    point -= pivot;

    // rotate point
    point.x = point.x * c - point.y * s;
    point.y = point.x * s + point.y * c;

    // translate point back:
    point += pivot;

    return point;
}

#define EPS 0.00001

/// @brief float comparison
bool is_approx(float value, float other_value)
{
    return abs(value - other_value) < EPS;
}

/// @brief float comparison with custom epsilon
bool is_approx(float value, float other_value, float eps)
{
    return abs(value - other_value) < eps;
}

/// @brief sine wave with set fequency, amplitude [0, 1], wave(0) = 0
float wave(float x, float frequency)
{
    return (sin(2 * PI * x * frequency - PI / 2) + 1) * 0.5;
}

/// @brief value of gaussian blur (size * size)-sized kernel at position x, y
float gaussian(int x, int y, int size)
{
    // source: https://github.com/Clemapfel/crisp/blob/main/.src/spatial_filter.inl#L337
    float sigma_sq = float(size);
    float center = size / 2;
    float length = sqrt((x - center) * (x - center) + (y - center) * (y - center));
    return exp((-1.f * (length / sigma_sq)) / sqrt(2 * PI + sigma_sq));
}

/// @brief component-wise sum
float sum(float arg){ return arg; }
float sum(vec2 arg) { return arg.x + arg.y; }
float sum(vec3 arg) { return arg.x + arg.y + arg.z; }
float sum(vec4 arg) { return arg.x + arg.y + arg.z + arg.w; }

/// @brief value of atan2
float atan2(in float y, in float x)
{
    // https://stackoverflow.com/questions/26070410/robust-atany-x-on-glsl-for-converting-xy-coordinate-to-angle
    bool s = (abs(x) > abs(y));
    return mix(PI / 2.0 - atan(x,y), atan(y,x), float(s));
}

/// @brief convert from component space to polar form
vec2 to_polar(in vec2 xy)
{
    return vec2(length(xy), atan2(xy.y, xy.x));
}

/// @brief convert from polar form to component space
vec2 from_polar(vec2 xy)
{
    float magnitude = xy.x;
    float angle = xy.y;
    return vec2(magnitude * cos(angle), magnitude * sin(angle));
}

/// @brief angle between two vectors
float angle(vec2 a, vec2 b)
{
    float dy = b.y - a.y;
    float dx = b.x - a.x;

    float theta = atan2(dy, dx);
    return theta;
}

/// @brief mode that properly wraps
float symmetrical_mod(float x)
{
    x = (2.0 * mod(x, 1.0)) - 1.0;
    if (x > 0.0)
        return mod(x, 1.0);
    else
        return mod(1.0 - x, 1.0);
}