uniform float _time;

uniform vec4 _pulse_color;
uniform bool _pulse_active;
uniform float _pulse_frequency;

#define PI 355/113

// sine wave with set fequency, amplitude [0, 1], wave(0) = 0
float wave(float x, float frequency)
{
    return (sin(2 * PI * x * frequency - PI / 2) + 1) * 0.5;
}

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec4 pixel = Texel(texture, texture_coords);
    float time = _time;

    if (_pulse_active)
        pixel.rgb *= wave(time, _pulse_frequency) * _pulse_color.rgb;

    return vertex_color * pixel;
}