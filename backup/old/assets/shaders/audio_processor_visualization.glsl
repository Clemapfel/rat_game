//#pragma language glsl3

#define PI 3.141592653

/// @brief normal distribution with peak at 0, 99 percentile in [-1, 1]
float gaussian(float x, float ramp)
{
    // e^{-\frac{4\pi}{3}\left(r\cdot\left(x-c\right)\right)^{2}}
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

float gaussian(float x)
{
    return gaussian(x, 2);
}

/// @brief attenuates values towards 0 and 1, with gaussian ramp
/// @param factor the higher, the sharper the ramp
float gaussian_bandpass(float x, float factor)
{
    // e^{-\frac{4\pi}{3}\left(ax\right)^{2}}
    return 1 - gaussian(factor * x) + gaussian(factor * (x - 1));
}

/// @brief attenuates values towards 0
float gaussian_lowpass(float x, float factor)
{
    return 1 - gaussian(factor * (x - 1));
}

/// @brief attenuates values towards 1
float gaussian_highpass(float x, float factor)
{
    return 1 - gaussian(factor * x);
}

/// @brief butterworth, same norm as gaussian
/// @param n integer, the higher the closer to box
float butterworth(float x, float factor, int n)
{
    // B\left(x\right)=\frac{1}{\left(1+\left(2x\right)^{2n}\right)}
    return 1 / (1 + pow(factor * x, 2 * n));
}

/// @brief
float gaussian_lowboost(float x, float cutoff, float ramp)
{
    if (x < cutoff)
        return 1.0;
    else
        return gaussian(x + cutoff, ramp);
}

/// @brief
float inverse_logboost(float x, float ramp)
{
    return log(ramp / x) - log(ramp) + 1;
}

/// @brief mean
float mean(float x) { return x; }
float mean(vec2 a) { return (a.x + a.y) / 2; }
float mean(vec3 a) { return (a.x + a.y + a.z) / 3; }
float mean(vec4 a) { return (a.x + a.y + a.z + a.w) / 4; }


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

uniform Image _spectrum;
uniform int _spectrum_size;

uniform Image _total_energy;

uniform bool _active;

uniform vec2 _texture_size;
uniform float _index;
uniform float _max_index;
uniform float _index_delta;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 screen_size = love_ScreenSize.xy;

    // smoothly scroll from the right
    float playhead = float(_index) / float(_max_index);
    float scale = float(100) / _max_index;
    texture_coords.x = texture_coords.x * scale - (1 * scale - playhead);

    float energy = Texel(_spectrum, texture_coords).x;
    float energy_delta = (Texel(_spectrum, texture_coords).y * 2) - 1;
    float energy_delta_delta = (Texel(_spectrum, texture_coords).z * 2) - 1;

    float total = Texel(_total_energy, texture_coords).x;
    float total_delta = Texel(_total_energy, texture_coords).y;

    return vec4(vec3(energy), 1);

    float value = clamp(energy_delta, 0, 1);
    float high_boost = (1 + gaussian(texture_coords.y - 0.25, 1));
    if (_active)
        value = energy * high_boost * (1 + energy_delta);
    else
        value = total * (1 + total_delta);

    return vec4(hsv_to_rgb(vec3(value, 1, value)), 1);
}