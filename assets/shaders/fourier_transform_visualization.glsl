#pragma language glsl3

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

uniform Image _spectrum;

uniform vec2 _texture_size;
uniform float _boost;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    texture_coords.xy = texture_coords.yx;
    vec2 pixel_size = vec2(1) / _texture_size;

    vec4 current = Texel(_spectrum, vec2(texture_coords.x, texture_coords.y));
    vec4 previous = Texel(_spectrum, vec2(texture_coords.x - pixel_size.x, texture_coords.y));

    const float boost_cutoff = 0;
    const float ramp = 7;
    const float amplitude = 3;
    current.x = current.x * inverse_logboost(current.x, 9);
    current.x = clamp(current.x, 0, 1);

    previous.y = abs(previous.y) / (2 * PI);
    current.y = abs(current.y) / (2 * PI);

    float value = current.x;
    float alpha = 1;

    return vec4(vec3(value), alpha);
}