#define PI 3.1415926535897932384626433832795

float gaussian(float x, float ramp) {
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}


float sine_wave(float x)
{
    return (sin(x) + 1) / 2;
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec2 normalization = vec2(1, love_ScreenSize.y / love_ScreenSize.x);
    float dist = distance(texture_coords * normalization, vec2(0.5) * normalization);
    const float fuzz = 0.1;
    float value = smoothstep(0, 2 * fuzz, dist - cos(elapsed));
    return vec4(1, 1, 1, value);
}

#endif
