float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (2.0 * 3.14159265359 * sigma * sigma);
}

#ifdef PIXEL

uniform float offset[3] = float[](0.0, 1.3846153846, 3.2307692308);
uniform float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);
uniform int vertical_or_horizontal = 1;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    vec4 color = Texel(image, vertex_position / love_ScreenSize.xy) * weight[0];
    if (vertical_or_horizontal == 1)
    {
        for (int i = 1; i < 3; i++) {
            color += texture2D(image, (vertex_position + vec2(0.0, offset[i])) / love_ScreenSize.xy) * weight[i];
            color += texture2D(image, (vertex_position - vec2(0.0, offset[i]) ) / love_ScreenSize.xy) * weight[i];
        }
    }
    else if (vertical_or_horizontal == 0)
    {
        for (int i = 1; i < 3; i++) {
            color += texture2D(image, (vertex_position + vec2(offset[i], 0.0)) / love_ScreenSize.xy) * weight[i];
            color += texture2D(image, (vertex_position - vec2(offset[i], 0.0) ) / love_ScreenSize.xy) * weight[i];
        }
    }

    return color;
}
#endif