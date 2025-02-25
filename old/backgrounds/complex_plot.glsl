#define PI 3.1415926535897932384626433832795

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

/// @brief convert hsv to rgb
vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// @param polar vec2 (magnitude, angle)
vec2 polar_to_complex(vec2 polar) {
    return vec2(polar.x * cos(polar.y), polar.x * sin(polar.y));
}

/// @param complex vec2 (real, imag)
vec2 complex_to_polar(vec2 complex) {
    return vec2(length(complex), atan(complex.y, complex.x));
}

vec2 complex_conjugate(vec2 a) {
    return vec2(a.x, -a.y);
}

vec2 complex_mul(vec2 a, vec2 b) {
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

vec2 complex_div(vec2 a, vec2 b) {
    return vec2(((a.x*b.x + a.y*b.y)/(b.x*b.x + b.y*b.y)),((a.y*b.x - a.x*b.y)/(b.x*b.x + b.y*b.y)));
}

vec2 complex_sin(vec2 a) {
    return vec2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y));
}

vec2 complex_cos(vec2 a) {
    return vec2(cos(a.x) * cosh(a.y), -sin(a.x) * sinh(a.y));
}

vec2 complex_tan(vec2 a) {
    return complex_div(complex_sin(a), complex_cos(a));
}

vec2 complex_log(vec2 a) {
    return vec2(log(sqrt((a.x*a.x)+(a.y*a.y))), atan(a.y,a.x));
}

vec2 complex_exp(vec2 z) {
    return vec2(exp(z.x) * cos(z.y),  exp(z.x) * sin(z.y));
}

vec2 complex_sqrt(vec2 z) {
    float x = z.x;
    float y = z.y;

    float magnitude = sqrt(x * x + y * y);
    float angle = atan(y, x) / 2.0;

    return vec2(sqrt(magnitude) * cos(angle), sqrt(magnitude) * sin(angle));
}

vec2 complex_atanh(vec2 z) {
    return 0.5 * complex_log(complex_div(vec2(1,0)+z,vec2(1,0)-z));
}


vec2 rotate(vec2 point, float angle)
{
    float s = sin(angle);
    float c = cos(angle);

    return vec2(point.x * c - point.y * s, point.x * s + point.y * c);
}


#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 2;
    float aspect_ratio = love_ScreenSize.x / love_ScreenSize.y;
    texture_coords.x = (texture_coords.x - 0.5) * aspect_ratio + 0.5;

    highp vec2 complex = 2 * (texture_coords - vec2(0.5));
    complex.y += 1.5;
    complex *= 4;

    float signal = (sin(time / 5) + 1) / 2;

    highp vec2 as_polar = complex_to_polar(complex);
    as_polar.x *= cos(complex.x - elapsed) + sin(complex.y + elapsed);
    as_polar = complex_div(as_polar * signal, as_polar.yx);
    //as_polar.y += time * as_polar.x;
    //as_polar.x *= atanh(as_polar.y);
    //as_polar.x = as_polar.x * (cos(as_polar.x + time) + sin(as_polar.y + time));
    //as_polar.y += elapsed * as_polar.x;
    //as_polar.x = cos(as_polar.x);

    float angle = as_polar.y;
    float magnitude = as_polar.x;
    float hue = as_polar.y / (2 * PI);
    float value = as_polar.x;
    return vec4(lch_to_rgb(vec3(fract(value), 1, fract(hue))), 1);
}

#endif
