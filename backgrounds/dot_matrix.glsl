
#define PI 3.1415926535897932384626433832795

float voronoise(vec3 p, float blur, float squareness) {
    blur = clamp(blur, 0, 1);
    float u = squareness;
    float k = 1.0 + 63.0 * pow(1.0 - blur, 6.0);
    vec3 i = floor(p);
    vec3 f = fract(p);

    float s = 1.0 + 31.0 * blur;
    vec2 a = vec2(0.0, 0.0);

    vec3 g = vec3(-2.0);
    for (g.z = -2.0; g.z <= 2.0; g.z++)
    for (g.y = -2.0; g.y <= 2.0; g.y++)
    for (g.x = -2.0; g.x <= 2.0; g.x++) {
        vec3 v = i + g;
        v = fract(v * vec3(.1031, .1030, .0973));
        v += dot(v, v.yxz + 19.19);
        vec3 o = fract((v.xxy + v.yzz) * v.zyx) * vec3(u, u, 1.);
        vec3 d = g - f + o + 0.5;
        float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
        a += vec2(o.z * w, w);
    }
    return a.x / a.y;
}

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

float project(float value, float lower, float upper) {
    return value * abs(upper - lower) + min(lower, upper);
}

float gaussian(float x, float mean, float variance) {
    return exp(-pow(x - mean, 2.0) / variance);
}

float map(float value, float inputMin, float inputMax, float outputMin, float outputMax) {
    return outputMin + ((outputMax - outputMin) / (inputMax - inputMin)) * (value - inputMin);
}

float sine_wave(float x, float lower, float upper) {
    return map((sin(2 * PI * x * 2 - PI / 2) + 1) * 0.5, -1, 1, lower, upper);
}

float square_wave(float x) {
    float smoothness = 100.0;
    return atan(smoothness * sin(2.0 * PI * x)) / PI + 0.5;
}

#ifdef PIXEL

uniform float radius;
uniform float elapsed;

vec4 effect(vec4 vertex_color, Image image, vec2 texture_coords, vec2 vertex_position)
{
    float time = elapsed / 10;

    float aspect_factor = love_ScreenSize.x / love_ScreenSize.y;
    vec2 pos = vertex_position / love_ScreenSize.xy;
    pos.x *= aspect_factor;

    float n_rows = 100;
    float radius = 1 / n_rows;
    float grid_size = radius * 2;

    int x_i = int(floor(pos.x / grid_size));
    int y_i = int(floor(pos.y / grid_size));

    vec2 center = vec2(float(x_i) * grid_size + radius, float(y_i) * grid_size + radius);

    float foreground_rng = voronoise(vec3(pos.xy * 7, time), 0.5, 0.5);
    float background_rng = gaussian(worley_noise(vec3(pos.xy * 4 + time * 2, 1)), 0, 0.3);

    const float eps = 0.005;
    const float cutoff = 0.5;
    if (foreground_rng >= cutoff - eps)
    radius = square_wave(foreground_rng) * gaussian(abs(foreground_rng - cutoff) / eps, 0, 0.7);
    else
    radius *= project(background_rng, 0.3, 1.6);

    float border = 0.005;
    float dist = radius - distance(pos, center);

    float value = 0.0;
    if (dist > border)
    value = 1.0;
    else if (dist > 0.0)
    value = dist / border;  // draw with feathered edge

    //return vec4(vec3(background_rng), 1);
    return vec4(clamp(vec3(0.8) - value, 0, 1), 1);
}

#endif
