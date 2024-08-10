uniform float elapsed;

float sine_wave(float x, float frequency) {
    return (sin(2.0 * 3.14159 * x * frequency - 3.14159 / 2.0) + 1.0) * 0.5;
}

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    const float amplitude = 0.3;
    float time = elapsed * 2;
    float sine = sine_wave(texture_coords.x + time + (abs(texture_coords.y - 0.5) * 0.8), 1.1) * (2 * amplitude) - amplitude;
    return vec4(vertex_color.rgb * (1 + sine), vertex_color.a);
}