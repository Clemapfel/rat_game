/// @brief 3d worley noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/worley.glsl
float worley_noise(vec3 p) {
    vec3 n = floor(p);
    vec3 f = fract(p);

    float dist = 1.0;
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 g = vec3(i, j, k);

                vec3 p = n + g;
                p = fract(p * vec3(0.1031, 0.1030, 0.0973));
                p += dot(p, p.yxz + 19.19);
                vec3 o = fract((p.xxy + p.yzz) * p.zyx);

                vec3 delta = g + o - f;
                float d = length(delta);
                dist = min(dist, d);
            }
        }
    }

    return 1 - dist;
}

#define PI 3.1415926535897932384626433832795

vec2 rotate(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * mat2(c, -s, s, c);
}

/// @brief bayer dithering
/// @source adapted from https://www.shadertoy.com/view/WstXR8
vec3 dither_4x4(vec3 color_a, vec3 color_b, float mix_fraction, vec2 screen_position) {
    const mat4 bayer_4x4 = mat4(
         0.0 / 16.0, 12.0 / 16.0,  3.0 / 16.0, 15.0 / 16.0,
         8.0 / 16.0,  4.0 / 16.0, 11.0 / 16.0,  7.0 / 16.0,
         2.0 / 16.0, 14.0 / 16.0,  1.0 / 16.0, 13.0 / 16.0,
        10.0 / 16.0,  6.0 / 16.0,  9.0 / 16.0,  5.0 / 16.0
    );

    vec3 color = mix(color_a, color_b, mix_fraction);
    color = pow(color.rgb, vec3(2.2)) - 0.004; // gamma correction
    float bayer_value = bayer_4x4[int(screen_position.x) % 4][int(screen_position.y) % 4];
    return vec3(step(bayer_value,color.r), step(bayer_value,color.g), step(bayer_value,color.b));
}

const uint MODE_TOON = 0u; 
const uint MODE_LINEAR = 1u; 
const uint MODE_DITHER = 2u;
const uint MODE_TOON_ANTI_ALIASED = 3u;
uniform uint color_mode = MODE_TOON_ANTI_ALIASED; // interpolation mode, cf. `grayscale_to_color`
uniform float color_mode_toon_aa_eps = 0.05;

uniform sampler2D palette_texture;   // palette texture
uniform int palette_y_index;         // y index of which palette to use, 1-based

uniform uint palette_offset = 6u;    // n pixels for background color palette to start
uniform uint palette_n_colors = 5u;  // n steps in background palette

vec3 grayscale_to_color(float gray, vec2 fragment_position)
{
    gray = clamp(gray, 0, 1);
    if (color_mode == MODE_TOON) {
        // get closest color in palette, only return colors from palette
        uint mapped = uint(floor(gray * palette_n_colors)) + palette_offset;
        return texelFetch(palette_texture, ivec2(mapped, palette_y_index - 1), 0).rgb;
    }
    else if (color_mode == MODE_TOON_ANTI_ALIASED) {
        uint mapped_left = uint(floor(gray * palette_n_colors)) + palette_offset;
        uint mapped_right = uint(floor(gray * palette_n_colors)) + palette_offset + 1u;
        mapped_right = clamp(mapped_right, palette_offset, palette_offset + palette_n_colors - 1u);
        vec4 left_color = texelFetch(palette_texture, ivec2(mapped_left, palette_y_index - 1), 0);
        vec4 right_color = texelFetch(palette_texture, ivec2(mapped_right, palette_y_index - 1), 0);
        float factor = 1 / float(palette_n_colors);
        float local_eps = mod(gray, factor) / factor;

        if (distance(local_eps, 1) < color_mode_toon_aa_eps)
            return mix(left_color, right_color, (local_eps - 1) / color_mode_toon_aa_eps).rgb;
        else
            return mix(left_color, right_color, 1 - step(local_eps, 1)).rgb;
    }
    else if (color_mode == MODE_LINEAR) {
        // get two closest colors in palette and linearly interpolate
        uint mapped_left = uint(floor(gray * palette_n_colors)) + palette_offset;
        uint mapped_right = uint(floor(gray * palette_n_colors)) + palette_offset + 1u;
        mapped_right = clamp(mapped_right, palette_offset, palette_offset + palette_n_colors - 1u);
        vec4 left_color = texelFetch(palette_texture, ivec2(mapped_left, palette_y_index - 1), 0);
        vec4 right_color = texelFetch(palette_texture, ivec2(mapped_right, palette_y_index - 1), 0);
        float factor = 1 / float(palette_n_colors);
        return mix(left_color, right_color, mod(gray, factor) / factor).rgb;
    }
    else if (color_mode == MODE_DITHER) {
        // get two closest colors and dither
        uint mapped_left = uint(floor(gray * palette_n_colors)) + palette_offset;
        uint mapped_right = uint(floor(gray * palette_n_colors)) + palette_offset;
        mapped_right = clamp(mapped_right, palette_offset, palette_offset + palette_n_colors - 1u);
        vec4 left_color = texelFetch(palette_texture, ivec2(mapped_left, palette_y_index - 1), 0);
        vec4 right_color = texelFetch(palette_texture, ivec2(mapped_right, palette_y_index - 1), 0);
        float factor = 1 / float(palette_n_colors);
        return dither_4x4(left_color.rgb, right_color.rgb, 0.5, vec2(fragment_position));
    }
    else
        discard; // invalid `color_mode`
}

uniform float time;
uniform float time_since_last_pulse;
uniform float pulse_max_dilation = 4; // maximum speedup after pulse
uniform float pulse_duration = 1; // duration of speedup
uniform float pulse_attack = 0.5; // in [0, 1]

float pulse_shape(float t, float ramp)
{
    // gaussian with peak at attack, width of duration
    return 1 - exp(-1 * pow(4 * PI / 3 * ramp * (t - pulse_attack) / pulse_duration, 2));
}

float dilation_from_pulse_t(float t) {
    float result;
    if (t < pulse_attack)
        result = pulse_shape(t, 3);
    else
        result = pulse_shape(t, 1);

    return result;
}

vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 fragment_position) {
    const float time_scale = 5;   // increase to slow down

    float elapsed = time / time_scale * dilation_from_pulse_t(time_since_last_pulse);

    vec2 uv = fragment_position / love_ScreenSize.xy;

    vec2 position = uv;
    position *= 10;

    float value = worley_noise(vec3(position + vec2(elapsed / 5, 0), elapsed / 10));
    value = smoothstep(0 - 0.01, 0 + 0.01, distance(uv.y, dilation_from_pulse_t(uv.x)));
    return vec4(grayscale_to_color(value, fragment_position), 1);
}
