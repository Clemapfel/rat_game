/*

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

uniform sampler2D palette_texture;
uniform int palette_y_index; // 1-based
uniform vec2 palette_size;

uniform uint palette_background_offset = 6u;
uniform uint palette_background_width = 5u;


#define MODE_NEAREST 0u  // get closest color in palette, can only return colors from palette
#define MODE_LINEAR 1u // get two closest colors in palette and linearly interpolate
#define MODE_DITHER 2u // get two closest colors and dither
const uint color_mode = MODE_DITHER;

float dither_4x4(vec2 position, float brightness) {
    int x = int(mod(position.x, 4.0));
    int y = int(mod(position.y, 4.0));
    int index = x + y * 4;
    float limit = 0.0;

    if (x < 8) {
        if (index == 0) limit = 0.0625;
        else if (index == 1) limit = 0.5625;
        else if (index == 2) limit = 0.1875;
        else if (index == 3) limit = 0.6875;
        else  if (index == 4) limit = 0.8125;
        else if (index == 5) limit = 0.3125;
        else if (index == 6) limit = 0.9375;
        else if (index == 7) limit = 0.4375;
        else if (index == 8) limit = 0.25;
        else if (index == 9) limit = 0.75;
        else if (index == 10) limit = 0.125;
        else if (index == 11) limit = 0.625;
        else if (index == 12) limit = 1.0;
        else if (index == 13) limit = 0.5;
        else if (index == 14) limit = 0.875;
        else if (index == 15) limit = 0.375;
    }

    return brightness < limit ? 0.0 : 1.0;
}

vec3 grayscale_to_color(vec2 uv, float gray)
{
    gray = clamp(gray, 0, 1);
    if (color_mode == MODE_NEAREST) {
        uint mapped = uint(floor(gray * palette_background_width)) + palette_background_offset;
        return texelFetch(palette_texture, ivec2(mapped, palette_y_index - 1), 0).rgb;
    }
    if (color_mode == MODE_LINEAR) {
        uint mapped_left = uint(floor(gray * palette_background_width)) + palette_background_offset;
        uint mapped_right = uint(floor(gray * palette_background_width)) + palette_background_offset + 1u;
        mapped_right = clamp(mapped_right, palette_background_offset, palette_background_offset + palette_background_width - 1u);
        vec4 left_color = texelFetch(palette_texture, ivec2(mapped_left, palette_y_index - 1), 0);
        vec4 right_color = texelFetch(palette_texture, ivec2(mapped_right, palette_y_index - 1), 0);
        float factor = 1 / float(palette_background_width);
        return mix(left_color, right_color, mod(gray, factor) / factor).rgb;
    }
    else if (color_mode == MODE_DITHER) {

        uint mapped_left = uint(floor(gray * palette_background_width)) + palette_background_offset;
        uint mapped_right = uint(floor(gray * palette_background_width)) + palette_background_offset + 1u;
        mapped_right = clamp(mapped_right, palette_background_offset, palette_background_offset + palette_background_width - 1u);
        vec4 left_color = texelFetch(palette_texture, ivec2(mapped_left, palette_y_index - 1), 0);
        vec4 right_color = texelFetch(palette_texture, ivec2(mapped_right, palette_y_index - 1), 0);
        float factor = 1 / float(palette_background_width);
        return vec3(dither_4x4(uv, mod(gray, factor) / factor ));
    //}

    return vec3(0);
}

uniform float time;

vec4 effect(vec4 color, Image image, vec2 uv, vec2 fragment_position) {
    const float space_scale = 100; // increase to zoom in
    const float time_scale = 5;   // increase to slow down

    vec2 position = fragment_position / space_scale;
    float elapsed = time / time_scale;
    float value = worley_noise(vec3(position, elapsed));
    return vec4(grayscale_to_color(uv, value), 1);
}
*/

mat4 bayerIndex = mat4(
vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

vec4 effect(vec4 color, Image image, vec2 uv, vec2 fragment_position) {
    // sample the texture
    vec4 col = mix(vec4(0, 1, 0, 1), vec4(1, 0, 1, 1), uv.x);

    // find bayer matrix entry based on fragment position
    float bayerValue = bayerIndex[int(fragment_position.x) % 4][int(fragment_position.y) % 4];
    return vec4(step(bayerValue,col.r), step(bayerValue,col.g), step(bayerValue,col.b), col.a);
}
