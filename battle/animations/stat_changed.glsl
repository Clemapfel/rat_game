/// @brief 3d discontinuous noise, in [0, 1]
vec3 random_3d(in vec3 p) {
    return fract(sin(vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

/// @brief gradient noise
/// @source adapted from https://github.com/patriciogonzalezvivo/lygia/blob/main/generative/gnoise.glsl
float gradient_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    float result = mix( mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( -1 + 2 * random_3d(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
    mix( dot( -1 + 2 * random_3d(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
    dot( -1 + 2 * random_3d(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );

    return result;
}

float random(float seed) {
    float dot_product = dot(vec2(seed, seed), vec2(12.9898,78.233));
    return fract(sin(dot_product) * 43758.5453123);
}

#ifdef PIXEL

uniform vec4 color;
uniform float elapsed;
uniform bool direction;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 screen_coords)
{
    const int n_columns = 5;
    const float arrow_length = 1.5; // the higher, the shorter the arrow
    float time = elapsed / 10;

    vec4 texel = Texel(image, texture_coords);
    float y = texture_coords.y + elapsed;
    float column_i = floor(texture_coords.x * n_columns);
    float column_width = 1.0 / n_columns;
    float column_center = column_i * column_width + 0.5 * column_width;
    float offset = (column_i / n_columns * -1) * sqrt(2 * n_columns);
    y = fract(column_i + y + offset + time - distance(texture_coords.x, column_center));
    y = clamp(sqrt(arrow_length * y), 0, 1);
    float mask = 1.0 - y;
    return vec4(mix(texel.rgb, color.rgb, mask), texel.a);
}
#endif