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
uniform int _spectrum_size;

uniform Image _energy;
uniform int _energy_size;

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
    float magnitude = Texel(_spectrum, texture_coords).x;

    /*
    float energy_step = 1.f / float(_energy_size);
    float energy_previous = Texel(_energy, vec2(texture_coords.x - energy_step, texture_coords.y)).x;
    float energy_current = Texel(_energy, vec2(texture_coords.x, texture_coords.y)).x;
    float energy_delta = clamp(energy_previous - energy_current, 0, 1);

    float spectrum_step = 1.f / _spectrum_size;
    float spectrum_previous = Texel(_spectrum, vec2(texture_coords.x - spectrum_step, texture_coords.y)).x;
    float spectrum_current = Texel(_spectrum, vec2(texture_coords.x, texture_coords.y)).x;
    float spectrum_delta = abs(spectrum_previous - spectrum_current);
    */

    float energy = Texel(_energy, texture_coords).x;
    float energy_delta = (Texel(_energy, texture_coords).y * 2) - 1;

    float value = !_active ? energy : clamp(energy_delta, 0, 1);
    vec3 as_hsv = vec3(0, 0, value);
    return vec4(hsv_to_rgb(as_hsv), 1);

    /*
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

    float project(float lower, float upper, float value)
    {
        return value * abs(upper - lower) + min(lower, upper);
    }

    float step = 1 / _energy_size.x;
    float energy =
        Texel(_energy, vec2(texture_coords.x + +1 * step, texture_coords.y)).x +
        Texel(_energy, vec2(texture_coords.x + +0 * step, texture_coords.y)).x +
        Texel(_energy, vec2(texture_coords.x + -1 * step, texture_coords.y)).x
    ;
    energy = energy / 3;

    if (_on == 1)
    {
        step = 1 / _spectrum_size.x;
        float now =
            Texel(_spectrum, vec2(texture_coords.x - 1 * step, texture_coords.y)).x +
            Texel(_spectrum, vec2(texture_coords.x - 0 * step, texture_coords.y)).x;
        now = now / 2;


        float high_frequency_boost_weight = 0.9 * (1 - gaussian_lowpass(1 - texture_coords.y + 0.0, 0.9));
        float mid_fequency_boost_weight =   0.4 * (1 - gaussian_lowpass(1 - texture_coords.y + 0.6, 1.5));
        float low_frequency_boost_weight =  0.6 * (1 - gaussian_lowpass(1 - texture_coords.y + 1.0, 1.5));

        float total_offset = 1.1;
        float total_weight = (total_offset * high_frequency_boost_weight + total_offset * mid_fequency_boost_weight + total_offset * low_frequency_boost_weight) / 3;

        magnitude = now;
        magnitude = mix(magnitude, magnitude / energy, total_weight);

        magnitude *= (1 - (1 * gaussian_lowpass(magnitude, 0.5)));
        magnitude = magnitude + 2 * gaussian_highpass(magnitude, 0.6);
    }

    float energy_delta = Texel(_energy, vec2(texture_coords.x + +1 * step, 1)).x - Texel(_energy, vec2(texture_coords.x + +0 * step, 1)).x;
    energy_delta = clamp(-1 * energy_delta, 0, 1);
    float gray = energy_delta * 0.5 * energy;
    float hsv = clamp(magnitude, 0, 1);
    return clamp(vec4(vec3(gray * 0.5) + hsv_to_rgb(vec3(clamp(hsv, 0.8, 1), 1, hsv)), 1), 0, 1);
    */
}