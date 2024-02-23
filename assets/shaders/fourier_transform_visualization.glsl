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
uniform vec2 _spectrum_size;

uniform Image _energy;
uniform vec2 _energy_size;

uniform vec2 _texture_size;
uniform float _index;
uniform int _on;

float laplacian_of_gaussian(int x, int y, int sigma)
{
    float sigma_4 = sigma * sigma * sigma * sigma;
    float sigma_2 = sigma * sigma;
    return 1 / (PI * sigma_4) * (1 - (x * x + y * y) / (2 * sigma_2)) * exp(-1 * (x*x + y*y) / (2 * sigma_2));
}

float laplacian(int x, int y, int sigma)
{
    if (x < 0)
        return -1.0;
    else if (x == 0)
        return float(sigma);
    else
        return 0.0;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec2 screen_size = love_ScreenSize.xy;
    vec2 pixel_size = vec2(1) / _texture_size;

    float magnitude = Texel(_spectrum, texture_coords).x;

    float step = 1 / _energy_size.x;
    float energy =
        //Texel(_energy, vec2(texture_coords.x + 2 * step, texture_coords.y)).x +
        //Texel(_energy, vec2(texture_coords.x + 1 * step, texture_coords.y)).x +
        Texel(_energy, vec2(texture_coords.x + 0 * step, texture_coords.y)).x +
        Texel(_energy, vec2(texture_coords.x + -1 * step, texture_coords.y)).x
    ;

    energy = energy / 5;

    if (_on == 1)
    {
        float step = 1 / _spectrum_size.x;
        float before = Texel(_spectrum, vec2(texture_coords.x + 0, texture_coords.y)).x;
        float now = Texel(_spectrum, vec2(texture_coords.x + step, texture_coords.y)).x;

        // normalize weaker frequencies
        float amplitude = 0.5;
        float ramp = 4;
        float weight = mix(
            amplitude * gaussian_lowpass(texture_coords.y, ramp),           // high frequency normalization strength
            amplitude * gaussian_lowpass(texture_coords.y + 0.4, ramp),     // mid frequency
        0.5);

        before = mix(before, before / energy, weight);
        before = clamp(before, 0, 1);

        now = mix(now, now / energy, weight);
        now = clamp(now, 0, 1);

        magnitude = now;

        //float delta = magnitude - energy;
        //magnitude *= (1 - gaussian_lowpass(delta, 1));
    }

    return vec4(vec3(magnitude), 1);
}