
vec3 srandom3(in vec3 p) {
    return -1. + 2. * fract(sin(vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6)))
    ) * 43758.5453123);
}

float gnoise(vec3 p) {
    vec3 i = floor(p);
    vec3 v = fract(p);

    vec3 u = v * v * v * (v *(v * 6.0 - 15.0) + 10.0);

    return mix( mix( mix( dot( srandom3(i + vec3(0.0,0.0,0.0)), v - vec3(0.0,0.0,0.0)),
                          dot( srandom3(i + vec3(1.0,0.0,0.0)), v - vec3(1.0,0.0,0.0)), u.x),
                     mix( dot( srandom3(i + vec3(0.0,1.0,0.0)), v - vec3(0.0,1.0,0.0)),
                          dot( srandom3(i + vec3(1.0,1.0,0.0)), v - vec3(1.0,1.0,0.0)), u.x), u.y),
                mix( mix( dot( srandom3(i + vec3(0.0,0.0,1.0)), v - vec3(0.0,0.0,1.0)),
                          dot( srandom3(i + vec3(1.0,0.0,1.0)), v - vec3(1.0,0.0,1.0)), u.x),
                     mix( dot( srandom3(i + vec3(0.0,1.0,1.0)), v - vec3(0.0,1.0,1.0)),
                          dot( srandom3(i + vec3(1.0,1.0,1.0)), v - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

float fractal_brownian_motion(vec3 p) {
    const float persistence = 0.5;
    const int n_octaves = 1;

    float amplitude = 0.5;
    float total = 0.0;
    float normalization = 0.0;

    for (int i = 0; i < n_octaves; ++i) {
        float noiseValue = gnoise(p) * 0.5 + 0.5;
        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
    }

    return total / normalization;
}

#ifdef PIXEL

uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 5;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos *= 10;

    return vec4(vec3(fractal_brownian_motion(vec3(pos, elapsed))), 1);
}

#endif