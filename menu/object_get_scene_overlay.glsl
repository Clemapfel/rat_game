#define PI 3.1415926535897932384626433832795

uniform float elapsed;
const float eps = 0.002;

float sine_wave_shape(float x, float y, float center_y, float y_height, float thickness, float elapsed_sign) {
    x = x + elapsed_sign * elapsed;
    float wave = center_y + (tan(sin(x)) / (PI / 2) * y_height / 2.0);
    float value = 1 - smoothstep(thickness - eps, thickness + eps, distance(y, wave));

    return value;
}

uniform float line_width;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position) {
    vec2 uv = texture_coords;

    float sine_height = tanh(sin(1.2 * elapsed)) * 0.13;
    float sine_thickness = line_width / max(love_ScreenSize.x, love_ScreenSize.y);
    float sine_frequency = 24;
    float sine_margin = 10 / love_ScreenSize.y + 0.13 / 2 + eps + sine_thickness;

    float top = sine_wave_shape(sine_frequency * uv.x + PI, uv.y, sine_margin, sine_height, sine_thickness, 1) +
    sine_wave_shape(sine_frequency * uv.x, uv.y, sine_margin, sine_height, sine_thickness, 1);
    top = clamp(top, 0, 1);

    float bottom = sine_wave_shape(sine_frequency * uv.x + PI, uv.y, 1 - sine_margin, sine_height, sine_thickness, -1) +
    sine_wave_shape(sine_frequency * uv.x, uv.y, 1 - sine_margin, sine_height, sine_thickness, -1);
    bottom = clamp(bottom, 0, 1);

    float value = top + bottom;
    return vec4(value);
}